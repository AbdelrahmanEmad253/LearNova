"""LearNova written level exam grader.

Railway service start command:
uvicorn scoring.level_exam_grader:app --host 0.0.0.0 --port $PORT

Required endpoint:
POST /grade-level-attempt

This version improves internal error reporting and avoids silent 500s.
"""
from __future__ import annotations

import json
import logging
import os
import re
from typing import Any, Optional

from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

from scoring.provider_client import generate_text, parse_json_object
from scoring.supabase_utils import get_client

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("level_exam_grader")

PASSING_SCORE = float(os.getenv("LEVEL_EXAM_PASSING_SCORE", "60"))
LEVEL_EXAM_BINARY_SCORING = os.getenv("LEVEL_EXAM_BINARY_SCORING", "true").lower() != "false"
APP_API_KEY = os.getenv("LEVEL_GRADER_API_KEY")

app = FastAPI(title="LearNova ML-AI Level Exam Grader")


class GradeRequest(BaseModel):
    attempt_id: str = Field(..., description="student_level_attempts.id")
    force_regrade: bool = False


class GradeResponse(BaseModel):
    ok: bool
    attempt_id: str
    score: float
    passed: bool
    provider: str
    model: str
    question_count: int


GRADE_SCHEMA = {
    "type": "object",
    "properties": {
        "questions": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "question_id": {"type": "string"},
                    "order_index": {"type": "integer"},
                    "score": {"type": "number", "minimum": 0, "maximum": 100},
                    "correct": {"type": "boolean"},
                    "feedback": {"type": "string"},
                    "missing_points": {"type": "array", "items": {"type": "string"}},
                },
                "required": ["question_id", "order_index", "score", "correct", "feedback", "missing_points"],
                "additionalProperties": False,
            },
        },
        "overall_feedback": {"type": "string"},
    },
    "required": ["questions", "overall_feedback"],
    "additionalProperties": False,
}


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "ok": True,
        "service": "level_exam_grader",
        "route": "/grade-level-attempt",
        "build_marker": "level-grader-deterministic-scoring-fix-003",
        "has_level_grader_api_key": bool(APP_API_KEY),
        "has_supabase_url": bool(os.getenv("SUPABASE_URL")),
        "has_supabase_service_role_key": bool(os.getenv("SUPABASE_SERVICE_ROLE_KEY")),
    }


@app.post("/grade-level-attempt", response_model=GradeResponse)
def grade_level_attempt(payload: GradeRequest, x_api_key: Optional[str] = Header(None)) -> GradeResponse:
    if APP_API_KEY and x_api_key != APP_API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")

    try:
        supabase = get_client()
    except Exception as exc:
        logger.exception("Supabase client initialization failed")
        raise HTTPException(
            status_code=500,
            detail={
                "error": "Supabase client initialization failed",
                "hint": "Check Railway env SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.",
                "exception": str(exc),
            },
        )

    attempt = _fetch_attempt(supabase, payload.attempt_id)

    if attempt.get("score") is not None and attempt.get("passed") is not None and not payload.force_regrade:
        return GradeResponse(
            ok=True,
            attempt_id=payload.attempt_id,
            score=float(attempt["score"]),
            passed=bool(attempt.get("passed")),
            provider="cached_db",
            model="cached_db",
            question_count=0,
        )

    questions = _fetch_questions(supabase, attempt["assessment_id"], attempt.get("difficulty"))

    if not questions:
        raise HTTPException(
            status_code=404,
            detail={
                "error": "No level questions found for assessment",
                "assessment_id": attempt.get("assessment_id"),
                "hint": "Check level_assessment_questions.assessment_id matches student_level_attempts.assessment_id.",
            },
        )

    normalized_answers = _normalize_answers(attempt.get("answers") or {})

    grading_items: list[dict[str, Any]] = []
    for display_order, q in enumerate(questions, start=1):
        qid = q["id"]
        db_order_key = str(q.get("order_index"))
        display_order_key = str(display_order)

        # Flutter may submit answers by:
        # 1) actual question_id
        # 2) DB order_index
        # 3) displayed order 1..12 after filtering by difficulty
        answer = (
            normalized_answers.get(qid)
            or normalized_answers.get(db_order_key)
            or normalized_answers.get(display_order_key)
            or normalized_answers.get(f"q{display_order_key}")
            or ""
        )

        grading_items.append(
            {
                "question_id": qid,
                "order_index": q.get("order_index"),
                "display_order": display_order,
                "question_text": q.get("question_text"),
                "rubric": _safe_json_or_text(q.get("ai_grading_rubric")),
                "student_answer": str(answer).strip(),
            }
        )

    system_prompt = (
        "You are Mitchy, LearNova's strict but fair written exam grader. "
        "Grade only against the provided rubric, not against external assumptions. "
        "A student can use different wording and still be correct if the meaning matches. "
        "Award partial credit for correct steps. Do not require exact phrasing. "
        "Return only valid JSON matching the schema."
    )

    user_prompt = json.dumps(
        {
            "task": "Grade these written level exam answers.",
            "grading_rules": [
                "Grade each question independently against its rubric.",
                "Use strict binary correctness for final scoring: correct answers should receive 100, incorrect answers should receive 0.",
                "Set correct=true only when the answer contains the required rubric meaning.",
                "Do not give high scores for vague, incomplete, or unrelated answers.",
                "If the answer is empty or unrelated, score 0 and correct=false.",
                "Feedback should be concise and actionable.",
            ],
            "questions": grading_items,
        },
        ensure_ascii=False,
    )

    try:
        result = generate_text(system_prompt, user_prompt, json_schema=GRADE_SCHEMA)
        parsed = parse_json_object(result.text)
        provider, model = result.provider, result.model
    except Exception as exc:
        logger.exception("Provider grading failed; using conservative local fallback: %s", exc)
        parsed = _local_grade_fallback(grading_items)
        provider, model = "local_rubric_fallback", "keyword_overlap"

    question_grades = _validate_question_grades(parsed, grading_items)

    if LEVEL_EXAM_BINARY_SCORING:
        correct_count = sum(1 for q in question_grades if q.get("correct") is True)
        overall_score = round((correct_count / len(question_grades)) * 100, 2)
    else:
        correct_count = sum(1 for q in question_grades if q.get("correct") is True)
        overall_score = round(sum(q["score"] for q in question_grades) / len(question_grades), 2)

    passed = overall_score >= PASSING_SCORE
    feedback = parsed.get("overall_feedback") or _build_overall_feedback(question_grades, overall_score)

    safe_payload = {
        "score": overall_score,
        "passed": passed,
        "mitchy_feedback": feedback,
        "grade_breakdown": {
            "provider": provider,
            "model": model,
            "binary_scoring": LEVEL_EXAM_BINARY_SCORING,
            "correct_count": correct_count,
            "total_questions": len(question_grades),
            "questions": question_grades,
        },
        "grading_status": "graded",
    }

    try:
        update_response = (
            supabase.table("student_level_attempts")
            .update(safe_payload)
            .eq("id", payload.attempt_id)
            .execute()
        )
    except Exception as exc:
        logger.exception("Failed to update student_level_attempts with grade result")
        raise HTTPException(
            status_code=500,
            detail={
                "error": "Failed to update student_level_attempts with grade result",
                "hint": (
                    "Run the schema patch. The usual missing column is "
                    "student_level_attempts.mitchy_feedback."
                ),
                "attempt_id": payload.attempt_id,
                "exception": str(exc),
                "payload_keys": list(safe_payload.keys()),
            },
        )

    if not update_response.data:
        logger.warning("student_level_attempts update returned no rows for attempt_id=%s", payload.attempt_id)

    try:
        supabase.rpc("mark_level_attempt_graded", {"p_attempt_id": payload.attempt_id}).execute()
    except Exception as exc:
        logger.warning("mark_level_attempt_graded RPC failed/skipped: %s", exc)

    return GradeResponse(
        ok=True,
        attempt_id=payload.attempt_id,
        score=overall_score,
        passed=passed,
        provider=provider,
        model=model,
        question_count=len(question_grades),
    )


def _fetch_attempt(supabase, attempt_id: str) -> dict[str, Any]:
    try:
        res = supabase.table("student_level_attempts").select("*").eq("id", attempt_id).single().execute()
    except Exception as exc:
        logger.exception("Failed to fetch student_level_attempts row")
        raise HTTPException(
            status_code=500,
            detail={
                "error": "Failed to fetch level attempt",
                "attempt_id": attempt_id,
                "exception": str(exc),
            },
        )

    if not res.data:
        raise HTTPException(status_code=404, detail={"error": "Attempt not found", "attempt_id": attempt_id})

    return res.data


def _fetch_questions(supabase, assessment_id: str, difficulty: Optional[str]) -> list[dict[str, Any]]:
    """Fetch only the 12 questions for the attempt difficulty.

    Current DB shape stores 36 questions per level assessment:
      easy: order_index 1-12
      mid:  order_index 13-24
      hard: order_index 25-36

    This prevents the grader from grading the wrong tier or averaging across
    all 36 questions.
    """
    start_order, end_order = _difficulty_order_range(difficulty)

    try:
        query = (
            supabase.table("level_assessment_questions")
            .select("id, question_text, ai_grading_rubric, order_index")
            .eq("assessment_id", assessment_id)
        )

        if start_order is not None and end_order is not None:
            query = query.gte("order_index", start_order).lte("order_index", end_order)

        res = query.order("order_index").execute()
    except Exception as exc:
        logger.exception("Failed to fetch level_assessment_questions")
        raise HTTPException(
            status_code=500,
            detail={
                "error": "Failed to fetch level assessment questions",
                "assessment_id": assessment_id,
                "difficulty": difficulty,
                "order_range": [start_order, end_order],
                "exception": str(exc),
            },
        )

    questions = res.data or []

    if questions:
        return questions

    # Fallback only for old/dirty data where difficulty order ranges were not inserted.
    try:
        fallback = (
            supabase.table("level_assessment_questions")
            .select("id, question_text, ai_grading_rubric, order_index")
            .eq("assessment_id", assessment_id)
            .order("order_index")
            .execute()
        )
    except Exception:
        raise

    fallback_questions = fallback.data or []

    if fallback_questions:
        logger.warning(
            "No questions found for assessment_id=%s difficulty=%s order_range=%s-%s; using all %s questions as fallback.",
            assessment_id,
            difficulty,
            start_order,
            end_order,
            len(fallback_questions),
        )

    return fallback_questions


def _difficulty_order_range(difficulty: Optional[str]) -> tuple[Optional[int], Optional[int]]:
    normalized = (difficulty or "").strip().lower()

    if normalized == "easy":
        return 1, 12

    if normalized in {"mid", "medium"}:
        return 13, 24

    if normalized == "hard":
        return 25, 36

    return None, None


def _normalize_answers(raw: Any) -> dict[str, Any]:
    if isinstance(raw, str):
        try:
            raw = json.loads(raw)
        except json.JSONDecodeError:
            return {"1": raw}

    if isinstance(raw, list):
        out = {}
        for i, item in enumerate(raw, start=1):
            if isinstance(item, dict):
                qid = item.get("question_id") or item.get("id") or str(i)
                out[str(qid)] = item.get("answer") or item.get("value") or item.get("text") or ""
            else:
                out[str(i)] = item
        return out

    if isinstance(raw, dict):
        return {str(k): v for k, v in raw.items()}

    return {}


def _safe_json_or_text(value: Any) -> Any:
    if value is None:
        return ""

    if isinstance(value, (dict, list)):
        return value

    text = str(value)

    try:
        return json.loads(text)
    except Exception:
        return text


def _validate_question_grades(parsed: dict[str, Any], items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_id = {
        str(q.get("question_id")): q
        for q in parsed.get("questions", [])
        if isinstance(q, dict) and q.get("question_id")
    }

    out = []

    for item in items:
        grade = by_id.get(item["question_id"])

        if not grade:
            grade = _local_grade_one(item)

        try:
            raw_score = max(0.0, min(100.0, float(grade.get("score", 0))))
        except Exception:
            raw_score = 0.0

        student_answer = str(item.get("student_answer") or "").strip()

        # Binary correctness prevents cases like:
        # 2 deliberately correct answers + several partial wrong answers => 82%.
        # A question is counted correct only if the grader score is at least 70
        # and the answer is not empty.
        is_correct = bool(student_answer) and raw_score >= 70.0
        binary_score = 100.0 if is_correct else 0.0

        out.append(
            {
                "question_id": item["question_id"],
                "order_index": int(item.get("order_index") or 0),
                "display_order": int(item.get("display_order") or 0),
                "score": binary_score if LEVEL_EXAM_BINARY_SCORING else raw_score,
                "raw_score": raw_score,
                "correct": is_correct,
                "feedback": str(grade.get("feedback") or "Reviewed against the rubric."),
                "missing_points": grade.get("missing_points")
                if isinstance(grade.get("missing_points"), list)
                else [],
            }
        )

    return out


def _local_grade_fallback(items: list[dict[str, Any]]) -> dict[str, Any]:
    grades = [_local_grade_one(item) for item in items]
    return {
        "questions": grades,
        "overall_feedback": (
            "Graded with conservative local rubric fallback because the AI provider chain was unavailable."
        ),
    }


def _local_grade_one(item: dict[str, Any]) -> dict[str, Any]:
    answer = str(item.get("student_answer") or "").lower()
    rubric_text = json.dumps(item.get("rubric"), ensure_ascii=False).lower()

    if not answer.strip():
        score = 0
    else:
        tokens = {t for t in re.findall(r"[a-zA-Z0-9_]+", rubric_text) if len(t) > 3}
        answer_tokens = set(re.findall(r"[a-zA-Z0-9_]+", answer))

        if not tokens:
            score = 50
        else:
            overlap = len(tokens & answer_tokens) / max(1, min(len(tokens), 20))
            score = max(10, min(70, round(overlap * 100)))

    return {
        "question_id": item["question_id"],
        "order_index": int(item.get("order_index") or 0),
        "score": score,
        "correct": score >= 70,
        "feedback": (
            "Matched against the expected rubric. Add missing key steps for full credit."
            if score
            else "No relevant answer was detected."
        ),
        "missing_points": [],
    }


def _build_overall_feedback(grades: list[dict[str, Any]], overall_score: float) -> str:
    weak = [str(g["order_index"]) for g in grades if g["score"] < 70]

    if not weak:
        return f"Strong work. Your written answers covered the required rubric points. Score: {overall_score}%."

    return f"Score: {overall_score}%. Review question(s) {', '.join(weak)} and add the missing rubric steps."
