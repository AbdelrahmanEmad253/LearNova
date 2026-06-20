# LearNova — Backend

The Railway-hosted backend service. This is where diagnostic scoring, track assignment, Mitchy's AI orchestration, and the daily analytics pipelines actually run.

## What lives here

This service is reached two ways, and the distinction matters for understanding the code:

1. **On-demand, via Supabase Edge Functions.** The Flutter app never calls this service directly — it calls a Supabase Edge Function, which authenticates the user via their Supabase session, then forwards the request here using a private API key. This service trusts that key, not the end user's session.
2. **On a schedule, via Railway cron services.** Several Python scripts in `analytics/` run on independent daily timers, connecting straight to Supabase with a service-role key. No Flutter app or HTTP request is involved in that path at all.

```
backend/
├── main.py                  FastAPI app — all HTTP endpoints
├── services/
│   ├── auth.py                API-key protection for endpoints
│   └── supabase_client.py     Service-role Supabase client
├── scoring/
│   ├── diagnostics.py          Scores the 5 onboarding diagnostic tests
│   ├── diagnostic_answer_key.py  Loads the answer-key seed
│   └── diagnostic_profile.py    Builds the routing payload, writes assigned_track
├── personalization/
│   ├── learnova_scoring.py      DA/DE/DS scoring formula (base + modifier)
│   └── track_weights.csv         Per-feature modifier weights
├── mitchy/
│   ├── core.py                 Orchestrates Mitchy's full reply pipeline
│   ├── gemini_client.py          Gemini REST client w/ model fallback
│   ├── chat_logic_v3.py           Local affective analysis + fallback replies
│   ├── json_repair.py             Repairs malformed LLM JSON output
│   ├── trend_tracker.py           Longitudinal sentiment tracking
│   └── db.py                    Chat session/message persistence
├── analytics/
│   ├── ml_pipeline_reviewed.py        Daily ML metrics pipeline
│   ├── daily_insight_generator_reviewed.py  Gemini-powered admin briefing
│   ├── streak_reset.py               Resets stale learning streaks
│   ├── expire_challenges.py           Expires + reschedules missed weekly challenges
│   ├── detect_drift2.py               Learning-style drift detector
│   ├── bayesian_engine3.py             Dirichlet-Bayesian learning-style updater
│   └── adapters.py                   Converts Supabase rows into module input shapes
└── requirements.txt
```

## The diagnostic scoring model

Onboarding runs five tests (personality, soft skills, learning style, career interest, cognitive aptitude). Every answer maps to a feature score via an answer-key seed (`question_key` + `selected_index` → feature contribution). Those features are normalized, combined with track-specific modifier weights, and blended with direct O*NET-based base scores:

```
final_track_score = 0.30 × base_score + 0.70 × modifier_score
assigned_track = argmax(final_DA, final_DE, final_DS)
```

There is no hard-coded answer-combination lookup table — with 251 questions across the five tests, the space of possible responses is far too large for that. The score is calculated, not looked up, which is what makes it reproducible and auditable rather than a black box.

## Mitchy's reliability model

LLM calls fail — quota limits, timeouts, malformed or empty JSON. Mitchy is built around the assumption that this *will* happen in production, not as an edge case:

- Empty model output is treated as a failure even if JSON parsing technically succeeded.
- Partial or invalid JSON triggers a local, rule-based fallback response rather than an error.
- A final non-empty-response guard runs before anything is saved or returned, so an empty assistant message can never reach the chat history.
- Unexpected exceptions in the chat endpoint return a safe fallback payload instead of an HTTP 500.

The result: Mitchy should never leave a student looking at a broken chat bubble, even when the underlying model call fails outright.

## Local setup

```bash
cd backend
python -m venv venv
venv\Scripts\activate        # Windows
pip install -r requirements.txt
```

Create a `.env` file (never commit this) with:

```
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
SCORING_API_KEY=
MITCHY_SERVICE_API_KEY=
GEMINI_API_KEY=
GEMINI_MODEL=gemini-2.5-flash
GEMINI_FALLBACK_MODELS=gemini-2.5-flash-lite,gemini-2.0-flash-lite
GEMINI_TIMEOUT_SECONDS=12
```

Run locally:

```bash
uvicorn main:app --reload
```

## Deployment

Deployed on Railway as 5 independent services from this same repository — one always-on web service and four scheduled cron services. See [`../database/README.md`](../database/README.md) for how this service connects to the database layer, and the project's deployment notes for the exact Railway service configuration.

| Service | Command | Schedule |
|---|---|---|
| Web (API) | `uvicorn main:app --host 0.0.0.0 --port $PORT` | always on |
| ML pipeline | `python analytics/ml_pipeline_reviewed.py` | daily |
| Daily insight | `python analytics/daily_insight_generator_reviewed.py` | daily, after ML pipeline |
| Streak reset | `python analytics/streak_reset.py` | daily |
| Expire challenges | `python analytics/expire_challenges.py` | daily |

## Status

Diagnostic scoring, track assignment, and the gamification scoring rules are implemented and tested. Mitchy's core orchestration is in active development.
