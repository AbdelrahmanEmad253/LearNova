"""Mitchy-triggered risk alert helper.

This file creates a risk_scores row and notifies admins when Mitchy detects a
high/critical-risk learner state.

It intentionally fails safely: a risk-alert failure must never break chat.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

from services.supabase_client import supabase

HIGH_RISK_STATES = {
    "frustrated",
    "burnout_fatigue",
    "anxious_overwhelmed",
    "overwhelmed",
    "helpless",
    "at_risk",
    "critical",
}


def _safe_float(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except Exception:
        return default


def _risk_level_and_score(*, sentiment_score: float, cognitive_load: float, learning_state: str) -> tuple[Optional[str], float]:
    state = (learning_state or "").strip().lower()

    sentiment_component = min(abs(sentiment_score), 1.0) if sentiment_score < 0 else 0.0
    cognitive_component = min(max(cognitive_load, 0.0), 1.0)

    score = max(sentiment_component, cognitive_component)

    if state in HIGH_RISK_STATES:
        score = max(score, 0.82)

    if sentiment_score <= -0.85 or cognitive_load >= 0.92 or state in {"burnout_fatigue", "anxious_overwhelmed", "critical"}:
        return "critical", max(score, 0.92)

    if sentiment_score <= -0.65 or cognitive_load >= 0.82 or state in HIGH_RISK_STATES:
        return "high", max(score, 0.82)

    return None, score


def _recent_open_high_risk_exists(user_id: str) -> bool:
    since = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()

    response = (
        supabase.table("risk_scores")
        .select("id, risk_level, alert_resolved, computed_at")
        .eq("user_id", user_id)
        .eq("alert_resolved", False)
        .gte("computed_at", since)
        .execute()
    )

    rows = response.data or []

    for row in rows:
        if row.get("risk_level") in {"high", "critical"}:
            return True

    return False


def maybe_create_mitchy_risk_alert(
    *,
    user_id: str,
    user_email: Optional[str],
    full_name: Optional[str],
    profile: Dict[str, Any],
    local_analysis: Dict[str, Any],
    final_output: Dict[str, Any],
    topic_id: Optional[str],
    module_id: Optional[str],
    screen_context: Optional[str],
    provider_chain_error: Optional[str],
) -> Dict[str, Any]:
    sentiment_score = _safe_float(final_output.get("sentiment_score", local_analysis.get("sentiment_score")))
    cognitive_load = _safe_float(final_output.get("cognitive_load", local_analysis.get("cognitive_load")))
    learning_state = str(final_output.get("learning_state") or local_analysis.get("learning_state") or "")

    risk_level, risk_score = _risk_level_and_score(
        sentiment_score=sentiment_score,
        cognitive_load=cognitive_load,
        learning_state=learning_state,
    )

    if not risk_level:
        return {
            "ok": True,
            "alert_created": False,
            "reason": "risk_threshold_not_met",
            "risk_score_estimate": round(risk_score, 4),
        }

    if _recent_open_high_risk_exists(user_id):
        return {
            "ok": True,
            "alert_created": False,
            "reason": "recent_open_high_risk_exists",
            "risk_level": risk_level,
            "risk_score": round(risk_score, 4),
        }

    feature_snapshot = {
        "source": "mitchy_core",
        "trigger": "mitchy_detected_risk",
        "sentiment_score": sentiment_score,
        "cognitive_load": cognitive_load,
        "learning_state": learning_state,
        "suggested_action": final_output.get("suggested_action"),
        "recommended_format": final_output.get("recommended_format"),
        "topic_id": topic_id,
        "module_id": module_id,
        "screen_context": screen_context,
        "provider_chain_error": provider_chain_error,
        "profile": {
            "assigned_track": profile.get("assigned_track") if isinstance(profile, dict) else None,
            "learning_style": profile.get("learning_style") if isinstance(profile, dict) else None,
            "learning_mode": profile.get("learning_mode") if isinstance(profile, dict) else None,
        },
        "student": {
            "email": user_email,
            "full_name": full_name,
        },
    }

    insert_response = (
        supabase.table("risk_scores")
        .insert(
            {
                "user_id": user_id,
                "risk_score": round(risk_score, 4),
                "risk_level": risk_level,
                "feature_snapshot": feature_snapshot,
                "alert_triggered": False,
                "alert_resolved": False,
            }
        )
        .execute()
    )

    rows = insert_response.data or []

    if not rows:
        return {
            "ok": False,
            "alert_created": False,
            "reason": "risk_score_insert_returned_no_rows",
        }

    risk_score_id = rows[0]["id"]

    notify_response = supabase.rpc(
        "notify_admins_for_risk_score",
        {"p_risk_score_id": risk_score_id},
    ).execute()

    return {
        "ok": True,
        "alert_created": True,
        "risk_score_id": risk_score_id,
        "notify_result": notify_response.data,
    }
