# LearNova — Thesis

The full academic thesis document for this project: problem statement, research methodology, system architecture, and findings.

## Contents

```
thesis/
└── LearNova_Thesis.pdf
```

## What's in it

The thesis documents the full case for LearNova as a graduation project, including:

- **The problem** — Egypt's education-to-employment gap (23.1% graduate unemployment, 133rd-of-141 global skills ranking), and the broader global pattern of students choosing majors with no reliable guidance.
- **Platform architecture** — the diagnostic onboarding model, adaptive content delivery, AI mentorship and risk-analysis engine, and the gamification system.
- **Research methodology** — a 351-record qualitative and quantitative dataset built from platform reviews, job postings, academic literature, and regional labor market data. See [`../research/`](../research) for the standalone findings document.
- **Design decision validation** — each major architectural choice (adaptive microlearning, multimodal content delivery, behavioral-biometric risk detection, collaborative gamification) is backed by cited 2020–2025 peer-reviewed research, not just product intuition.

## Why this matters for the engineering

The system isn't designed around guesses about what students want — every major feature in [`../backend/`](../backend), [`../mobile-app/`](../mobile-app), and [`../database/`](../database) traces back to a specific, cited finding in this document. If you're trying to understand *why* a feature exists the way it does (e.g. why content has three formats instead of one, why gamification is team-based rather than individual leaderboards), this is the source of truth.
