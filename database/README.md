# LearNova — Database

PostgreSQL via Supabase, with Row Level Security enforced on every table, and the Edge Functions layer that bridges the Flutter app to the Railway backend.

## Structure

```
database/
├── schema/
│   └── supabase_schema_documentation.md   Full table-by-table schema reference
└── edge-functions/
    ├── consume-resource/index.ts            Topic resource XP + streak tracking
    ├── mitchy-chat/index.ts                  Forwards chat to Mitchy, handles fallback
    ├── run-scoring-engine/index.ts            Triggers diagnostic scoring on Railway
    ├── submit-module-attempt/index.ts          Module exam grading + XP
    └── submit-challenge-attempt/index.ts        Weekly challenge grading + perks + scheduling
```

> **Setup note:** if you're initializing this schema in a fresh Supabase project, the `handle_new_user()` trigger (which auto-populates the `users` table from `auth.users` on signup) needs to be set up first. See `schema/supabase_schema_documentation.md` for the trigger reference.

## Why Edge Functions exist at all

The Flutter app holds only a Supabase URL and an anon key — nothing that can write XP, grade an exam, or call the AI backend directly. Every privileged action goes through an Edge Function, which:

1. Verifies the caller's Supabase session (`auth.getUser()`).
2. Performs the privileged read/write using the service-role key, which never leaves the server.
3. For anything that needs real computation (scoring, AI generation), forwards a server-to-server request to the Railway backend using a private API key.

This means a compromised or reverse-engineered Flutter client still can't mint itself XP, fake an exam pass, or impersonate another student — every write path is re-validated server-side regardless of what the client claims.

## Schema design highlights

- **Strict content hierarchy.** `courses → levels → modules → topics`, each independently gated by `is_active`, so admins can stage content without it being visible to students.
- **Three-format adaptive content.** `topic_resources.format_type` (Visual / Auditory / Textual) is what lets the same lesson be served differently per student, driven by `student_profiles.learning_style` and a running Bayesian posterior (`bayesian_alpha_visual/auditory/textual`).
- **Full audit trail on risk detection.** `risk_scores.feature_snapshot` stores the exact ML feature values behind every computed risk score, so a flagged "high risk" alert is explainable after the fact, not a black-box number.
- **Gamification as its own subsystem.** XP, streaks, badges, and weekly challenges are deliberately isolated into `student_perks`, `student_challenge_schedule`, `user_streaks`, and `achievements_dictionary` rather than bolted onto `student_profiles`, so the scoring rules can evolve independently of the core learning model.

## A bug worth documenting: composite uniqueness constraints

During a schema audit against the live database dump, several multi-column `UNIQUE` constraints were found to have been created covering only their *last* listed column instead of the full intended combination — for example, `diagnostic_test_results` was constrained to `UNIQUE (test_number)` platform-wide, instead of `UNIQUE (user_id, test_number)` per student.

Left unfixed, this would have meant the entire platform could only support a single real user going through onboarding, leaderboards, or achievements before every subsequent student silently failed to save their results. It reproduced reliably and affected nine tables, all following the identical broken pattern — consistent with a schema-generation or migration-tooling issue rather than nine independent typos.

**Fix:** every affected constraint was dropped and recreated with its full intended column list, verified against `pg_constraint` afterward. This is the kind of failure mode that's invisible in single-developer testing and only shows up under real multi-user load — exactly the gap a schema audit is meant to catch before it does.

## Row Level Security

Two roles, enforced via an `is_admin()` helper function checked against `auth.uid()`:

| | Students | Admins |
|---|---|---|
| Own data (profile, progress, attempts, chat) | Read & write own rows only | Full read |
| Course content, assessments | Read `is_active = true` rows only | Full CRUD |
| Risk scores, sentiment history | No access | Read/update only |
| Intervention logs | No access | Scoped to their own admin actions |

Full policy-by-policy breakdown is in `schema/supabase_schema_documentation.md`.

## Status

Core schema, RLS policies, and the gamification subsystem (perks, weekly challenge scheduling, badges) are implemented and live. Edge Functions for diagnostic scoring, module/challenge grading, and Mitchy chat are deployed; level-exam grading (AI-graded, via Mitchy) is in progress.
