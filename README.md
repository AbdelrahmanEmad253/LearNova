<div align="center">

# LearNova

**An AI-driven adaptive learning platform that profiles how a student thinks, then reshapes the curriculum around it.**

[![Status](https://img.shields.io/badge/status-in%20development-yellow)]()
[![Platform](https://img.shields.io/badge/platform-Flutter-02569B)]()
[![Backend](https://img.shields.io/badge/backend-FastAPI%20%2B%20Railway-009688)]()
[![Database](https://img.shields.io/badge/database-Supabase%20(PostgreSQL)-3ECF8E)]()

</div>

---

## What this is

Most e-learning platforms hand every student the same video, the same article, the same pacing — regardless of how that person actually learns best. LearNova starts from a different premise: run a real psychometric and cognitive diagnostic up front (personality, learning style, aptitude, career interest), use it to route the student into a specialization, and then keep adapting — content format, difficulty, pacing, and intervention — as the platform observes how the student actually engages.

At the center of that adaptive loop is **Mitchy**, an AI mentor that doesn't just answer questions — it tracks sentiment and cognitive load over time, detects burnout before it becomes dropout, and recommends format or pacing changes via a Bayesian learning-style model running in the background.

This repository is the full system: mobile app, backend services, database, and the research and design work behind them.

> **Note:** This is an active student-built project, not a finished commercial product. Some pieces described below are complete and deployed; others are in progress. Each subdirectory's README is explicit about what's implemented versus planned.

---

## How it works, at a glance

```
┌─────────────────┐         ┌──────────────────────┐         ┌─────────────────────┐
│   Flutter App     │  <--->  │  Supabase Edge Funcs   │  <--->  │  Railway Backend       │
│  (student-facing)  │  HTTPS  │  (auth + routing layer) │  HTTPS  │  (FastAPI + Mitchy AI) │
└─────────────────┘         └──────────────────────┘         └─────────────────────┘
                                       │
                                       ▼
                              ┌──────────────────┐
                              │  PostgreSQL (RLS)   │
                              │  via Supabase        │
                              └──────────────────┘
```

The Flutter app never talks to the Railway backend directly. Every request is authenticated and forwarded through a Supabase Edge Function, which holds the only credentials trusted to call Railway's internal scoring, diagnostic, and AI-chat endpoints. This keeps service keys out of the mobile client entirely and gives every write path a single, auditable choke point.

| Layer | What it does | Where |
|---|---|---|
| **Mobile app** | Student-facing UI: onboarding diagnostics, adaptive lessons, chat with Mitchy, gamification (XP, streaks, badges, weekly challenges) | [`mobile-app/`](./mobile-app) |
| **Backend** | Diagnostic scoring, track assignment (Data Analytics / Engineering / Science), Mitchy's AI orchestration, daily ML/risk analytics, cron pipelines | [`backend/`](./backend) |
| **Database** | PostgreSQL schema, Row Level Security policies, Edge Functions (the secure bridge between app and backend) | [`database/`](./database) |
| **Design** | Full UI/UX specification for both the mobile app and an eventual web admin console | [`design/`](./design) |
| **Research** | A 351-record market research study validating the problem this project solves | [`research/`](./research) |
| **Thesis** | The full academic writeup: architecture, methodology, and findings | [`thesis/`](./thesis) |

---

## A few things worth knowing about the engineering

- **Server-side scoring only.** Diagnostic results, XP, and exam scores are never computed or written client-side — the Flutter app submits raw answers, and a Supabase Edge Function forwards them to Railway for scoring under a service-role key the client never sees.
- **A real psychometric model, not a quiz.** Track assignment isn't a lookup table — it's an additive weighted scoring model (Big Five personality, VARK learning style, RIASEC career interest, cognitive aptitude) with documented, reproducible formulas. See [`backend/README.md`](./backend/README.md) for the math.
- **Mitchy degrades gracefully.** The AI mentor's primary LLM calls can fail (rate limits, timeouts, malformed JSON) — the system is built to always return a usable response to the student rather than a broken chat bubble, with a local fallback layer underneath the AI layer.
- **A live, fixed bug worth mentioning.** During development, a schema audit caught that several composite uniqueness constraints (e.g. "one diagnostic result per student per test") had been collapsed to single-column constraints, which would have silently broken multi-user behavior. Caught and fixed before it shipped — see [`database/README.md`](./database/README.md) for the writeup.

---

## Tech stack

| Area | Technology |
|---|---|
| Mobile | Flutter (Dart) |
| Backend API | Python, FastAPI, hosted on Railway |
| Background jobs | Railway cron services (Python) |
| Database | PostgreSQL via Supabase, with Row Level Security on every table |
| Serverless glue layer | Supabase Edge Functions (TypeScript / Deno) |
| AI — conversational | Claude API (Mitchy's chat responses) |
| AI — daily insights | Gemini API (admin briefing generator) |

---

## Repository structure

```
LearNova/
├── docs/            Architecture diagrams and shared images
├── thesis/          Full academic thesis document
├── research/         Market research study (351-record dataset)
├── design/           UI/UX specifications — mobile app and web admin console
├── mobile-app/        Flutter client
├── backend/          Railway-hosted FastAPI service + Mitchy AI engine
└── database/          Supabase schema, RLS policies, and Edge Functions
```

Each directory has its own README with setup instructions and a description of what lives there.

---

## Team

| Name | Role |
|---|---|
| **Abdelrahman El Sherif** | Team Lead · Project Management · Data Engineering & Database Architecture |
| **Abdelrahman Ehssan** | AI/ML Engineering · Railway Backend Services |
| **Adham Emad** | Mobile Engineering (Flutter) |
| **Abdelrahman Sergany** | UI/UX Design |

---

## Status

This project is under active development as a university graduation project. It is not yet publicly deployed. Contributions, questions, and feedback from engineers are welcome via Issues.

---

<div align="center">
<sub>Built as a graduation project. See <a href="./thesis">thesis/</a> for the full research and methodology behind the platform.</sub>
</div>
