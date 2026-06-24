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

from scoring.provider_client import ProviderChainError, generate_text, provider_status
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
        "build_marker": "level-grader-plain-text-batch-fix-006",
        "provider_status": provider_status(),
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

    # Important design change:
    # Do NOT require JSON output from providers. Several providers/models return
    # good natural language but fail strict JSON parsing. For level grading we use
    # a pipe-delimited plain-text contract and parse it defensively.
    question_grades, provider, model, provider_errors, raw_provider_output = _grade_with_plain_text_batch(grading_items)



    if LEVEL_EXAM_BINARY_SCORING:
        correct_count = sum(1 for q in question_grades if q.get("correct") is True)
        overall_score = round((correct_count / len(question_grades)) * 100, 2)
    else:
        correct_count = sum(1 for q in question_grades if q.get("correct") is True)
        overall_score = round(sum(q["score"] for q in question_grades) / len(question_grades), 2)

    passed = overall_score >= PASSING_SCORE
    feedback = _build_overall_feedback(question_grades, overall_score)

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
            "provider_errors": provider_errors,
            "raw_provider_output_preview": raw_provider_output[:3000] if raw_provider_output else None,
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




def _grade_with_plain_text_batch(
    grading_items: list[dict[str, Any]]
) -> tuple[list[dict[str, Any]], str, str, list[str], str]:
    """Grade all answered questions using provider plain text, not JSON.

    This fixes the current production problem where providers return useful text
    but the grader fails because the output is not valid JSON.
    """
    non_empty_items = [
        item for item in grading_items
        if str(item.get("student_answer") or "").strip()
    ]

    # Blank questions should not poison the whole exam. They are simply wrong.
    grades_by_id: dict[str, dict[str, Any]] = {
        item["question_id"]: _blank_grade(item)
        for item in grading_items
        if not str(item.get("student_answer") or "").strip()
    }

    provider = "none"
    model = "none"
    provider_errors: list[str] = []
    raw_output = ""

    if non_empty_items:
        try:
            result = _call_plain_text_grader(non_empty_items)
            provider = result.provider
            model = result.model
            raw_output = result.text or ""
            parsed_grades = _parse_plain_text_grade_lines(raw_output, non_empty_items)

            grades_by_id.update(parsed_grades)

            missing_items = [
                item for item in non_empty_items
                if item["question_id"] not in parsed_grades
            ]

            if missing_items:
                provider_errors.append(
                    f"provider_output_parse_partial: parsed {len(parsed_grades)} of {len(non_empty_items)} answered item(s); local fallback used for the rest"
                )
                for item in missing_items:
                    grades_by_id[item["question_id"]] = _local_grade_one(item)
                    grades_by_id[item["question_id"]]["provider_parse_fallback"] = True

        except ProviderChainError as exc:
            provider = "local_keyword_fallback"
            model = "provider_chain_failed"
            provider_errors.extend(exc.errors)
            logger.warning("Provider chain failed; using local fallback per answered question: %s", exc)
            for item in non_empty_items:
                grades_by_id[item["question_id"]] = _local_grade_one(item)
                grades_by_id[item["question_id"]]["provider_failure_fallback"] = True

        except Exception as exc:
            provider = "local_keyword_fallback"
            model = "plain_text_grader_exception"
            provider_errors.append(f"{type(exc).__name__}: {str(exc)}")
            logger.warning("Plain text grading failed; using local fallback: %s", exc)
            for item in non_empty_items:
                grades_by_id[item["question_id"]] = _local_grade_one(item)
                grades_by_id[item["question_id"]]["provider_failure_fallback"] = True

    question_grades: list[dict[str, Any]] = []
    for item in grading_items:
        grade = grades_by_id.get(item["question_id"]) or _local_grade_one(item)
        question_grades.append(_normalize_final_grade(grade, item))

    if provider == "none":
        provider = "local_blank_only"
        model = "no_answered_questions"

    return question_grades, provider, model, provider_errors, raw_output


def _call_plain_text_grader(items: list[dict[str, Any]]):
    system_prompt = (
        "You are LearNova's strict written exam grader. "
        "Grade only against the rubric. "
        "Do not return JSON. Do not use markdown. "
        "Return one pipe-delimited line per question only."
    )

    compact_items = []
    for item in items:
        compact_items.append({
            "question_id": item["question_id"],
            "order_index": item.get("order_index"),
            "question_text": item.get("question_text"),
            "rubric": item.get("rubric"),
            "student_answer": item.get("student_answer"),
        })

    user_prompt = (
        "Grade these written answers.\\n"
        "For each question, return exactly one line using this format:\\n"
        "QUESTION_ID|ORDER_INDEX|CORRECT|short feedback\\n"
        "or\\n"
        "QUESTION_ID|ORDER_INDEX|INCORRECT|short feedback\\n\\n"
        "Rules:\\n"
        "- Use CORRECT only if the answer satisfies the important rubric meaning.\\n"
        "- Use INCORRECT for blank, random, vague, unrelated, or insufficient answers.\\n"
        "- Do not give partial credit in the output. The backend will calculate the score.\\n"
        "- Do not return JSON. Do not include explanations before or after the lines.\\n\\n"
        "Questions:\\n"
        + json.dumps(compact_items, ensure_ascii=False)
    )

    return generate_text(system_prompt, user_prompt, json_schema=None)


def _parse_plain_text_grade_lines(
    text: str,
    items: list[dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    by_id = {item["question_id"]: item for item in items}
    parsed: dict[str, dict[str, Any]] = {}

    raw_text = str(text or "").strip()
    if not raw_text:
        return parsed

    # Remove code fences if a model ignores instructions.
    raw_text = re.sub(r"^```(?:text|txt)?\\s*", "", raw_text.strip(), flags=re.IGNORECASE)
    raw_text = re.sub(r"\\s*```$", "", raw_text.strip())

    for line in raw_text.splitlines():
        cleaned = line.strip().strip("-* ")
        if not cleaned:
            continue

        # Preferred format: question_id|order|CORRECT|feedback
        parts = [part.strip() for part in cleaned.split("|")]
        if len(parts) >= 3:
            qid = parts[0]
            verdict = parts[2].upper()
            if qid in by_id and verdict in {"CORRECT", "INCORRECT", "WRONG", "FALSE", "TRUE"}:
                is_correct = verdict in {"CORRECT", "TRUE"}
                parsed[qid] = {
                    "question_id": qid,
                    "order_index": by_id[qid].get("order_index"),
                    "score": 100 if is_correct else 0,
                    "correct": is_correct,
                    "feedback": parts[3] if len(parts) >= 4 and parts[3] else _default_feedback(is_correct),
                    "missing_points": [],
                    "grading_source": "provider_plain_text",
                }
                continue

        # Defensive parsing: find any known question_id in the line.
        for qid, item in by_id.items():
            if qid in cleaned:
                upper = cleaned.upper()
                if "INCORRECT" in upper or "WRONG" in upper or "FALSE" in upper:
                    is_correct = False
                elif "CORRECT" in upper or "TRUE" in upper:
                    is_correct = True
                else:
                    continue

                parsed[qid] = {
                    "question_id": qid,
                    "order_index": item.get("order_index"),
                    "score": 100 if is_correct else 0,
                    "correct": is_correct,
                    "feedback": _extract_feedback_from_line(cleaned) or _default_feedback(is_correct),
                    "missing_points": [],
                    "grading_source": "provider_plain_text_defensive_parse",
                }

    return parsed


def _extract_feedback_from_line(line: str) -> str:
    parts = [part.strip() for part in line.split("|")]
    if len(parts) >= 4 and parts[3]:
        return parts[3]
    return ""


def _default_feedback(is_correct: bool) -> str:
    return (
        "Answer satisfies the required rubric meaning."
        if is_correct
        else "Answer does not satisfy the required rubric meaning."
    )


def _blank_grade(item: dict[str, Any]) -> dict[str, Any]:
    return {
        "question_id": item["question_id"],
        "order_index": int(item.get("order_index") or 0),
        "score": 0,
        "correct": False,
        "feedback": "No answer was provided for this question.",
        "missing_points": [],
        "grading_source": "blank_answer",
    }


def _normalize_final_grade(grade: dict[str, Any], item: dict[str, Any]) -> dict[str, Any]:
    student_answer = str(item.get("student_answer") or "").strip()

    if not student_answer:
        is_correct = False
        raw_score = 0.0
    else:
        try:
            raw_score = max(0.0, min(100.0, float(grade.get("score", 0))))
        except Exception:
            raw_score = 0.0

        is_correct = bool(grade.get("correct")) and raw_score >= 70.0

    binary_score = 100.0 if is_correct else 0.0

    return {
        "question_id": item["question_id"],
        "order_index": int(item.get("order_index") or 0),
        "display_order": int(item.get("display_order") or 0),
        "score": binary_score if LEVEL_EXAM_BINARY_SCORING else raw_score,
        "raw_score": raw_score,
        "correct": is_correct,
        "feedback": str(grade.get("feedback") or _default_feedback(is_correct)),
        "missing_points": grade.get("missing_points")
        if isinstance(grade.get("missing_points"), list)
        else [],
        "grading_source": grade.get("grading_source") or "normalized",
        "provider_parse_fallback": bool(grade.get("provider_parse_fallback")),
        "provider_failure_fallback": bool(grade.get("provider_failure_fallback")),
    }



def _mark_attempt_provider_failed(
    *,
    supabase,
    attempt_id: str,
    error_message: str,
    provider_errors: list[str],
) -> None:
    """Record provider failure without assigning a false 0% grade."""
    payload = {
        "score": None,
        "passed": None,
        "mitchy_feedback": (
            "Level exam grading was not completed because the AI provider chain "
            "was unavailable. Please retry after provider configuration is fixed."
        ),
        "grade_breakdown": {
            "provider": "provider_chain_unavailable",
            "model": None,
            "grading_completed": False,
            "provider_errors": provider_errors,
            "error_message": error_message,
            "provider_status": provider_status(),
        },
        "grading_status": "failed",
    }

    try:
        supabase.table("student_level_attempts").update(payload).eq("id", attempt_id).execute()
    except Exception as exc:
        logger.warning("Failed to mark attempt provider failure: %s", exc)


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
    """Fetch the correct level questions for the attempt difficulty.

    Supports both DB shapes:
    1) One assessment has 36 questions:
       easy 1-12, mid 13-24, hard 25-36.
    2) Each difficulty has its own assessment row:
       questions can be order_index 1-12 with difficulty set on rows.

    This avoids grading the wrong tier or accidentally mixing difficulties.
    """
    normalized_difficulty = (difficulty or "").strip().lower()
    start_order, end_order = _difficulty_order_range(normalized_difficulty)

    # First try explicit difficulty column if it exists/is populated.
    if normalized_difficulty in {"easy", "mid", "hard"}:
        try:
            by_difficulty = (
                supabase.table("level_assessment_questions")
                .select("id, question_text, ai_grading_rubric, order_index, difficulty")
                .eq("assessment_id", assessment_id)
                .eq("difficulty", normalized_difficulty)
                .order("order_index")
                .execute()
            )
            questions = by_difficulty.data or []
            if questions:
                return questions
        except Exception as exc:
            logger.warning("Fetch by difficulty failed, trying order range: %s", exc)

    # Then try historical order ranges.
    try:
        query = (
            supabase.table("level_assessment_questions")
            .select("id, question_text, ai_grading_rubric, order_index, difficulty")
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

    # Last fallback: all questions for the assessment. This is only for dirty/old data.
    try:
        fallback = (
            supabase.table("level_assessment_questions")
            .select("id, question_text, ai_grading_rubric, order_index, difficulty")
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
    """Normalize every supported Flutter answer payload into a question-id map.

    Critical fix:
    Supabase stores level answers as {"answers": [{"question_id": ..., "essay_answer": ...}]}.
    Older grader code ignored the nested "answers" list and ignored "essay_answer",
    so real written answers were treated as empty.
    """
    if isinstance(raw, str):
        try:
            raw = json.loads(raw)
        except json.JSONDecodeError:
            return {"1": raw}

    # Common stored shape: {"answers": [ ... ]}
    if isinstance(raw, dict):
        for list_key in ("answers", "responses", "items", "data"):
            if isinstance(raw.get(list_key), list):
                return _normalize_answers(raw[list_key])

        # Direct object keyed by question_id/order.
        return {str(k): v for k, v in raw.items()}

    if isinstance(raw, list):
        out: dict[str, Any] = {}

        for i, item in enumerate(raw, start=1):
            if isinstance(item, dict):
                answer_value = _extract_answer_text(item)
                keys = [
                    item.get("question_id"),
                    item.get("id"),
                    item.get("question_key"),
                    item.get("order_index"),
                    item.get("display_order"),
                    str(i),
                    f"q{i}",
                ]

                for key in keys:
                    if key is None:
                        continue

                    normalized_key = str(key)

                    # Prefer the latest non-empty answer if duplicates exist.
                    if str(answer_value).strip() or normalized_key not in out:
                        out[normalized_key] = answer_value
            else:
                out[str(i)] = item
                out[f"q{i}"] = item

        return out

    return {}


def _extract_answer_text(item: dict[str, Any]) -> Any:
    """Extract written answer text from all known frontend key names."""
    for key in (
        "essay_answer",
        "answer",
        "value",
        "text",
        "selected_answer",
        "selectedAnswer",
        "response",
        "content",
    ):
        value = item.get(key)

        if value is not None:
            return value

    return ""


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
            "Some answers were graded with local keyword fallback because provider output was unavailable or unparsable."
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
