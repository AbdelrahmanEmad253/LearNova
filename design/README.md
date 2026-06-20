# LearNova — Design

UI/UX specifications for both the student-facing mobile app and the (planned) web admin console.

## Contents

```
design/
├── LearNova_App_UI.pdf     Full mobile app UI specification
└── LearNova_Web_UI.pdf      Web admin console UI specification
```

## What's in each

- **`LearNova_App_UI.pdf`** — the complete student-facing design: onboarding/diagnostic flow, the adaptive lesson player (Visual/Auditory/Textual variants), Mitchy's chat interface, and the gamification screens (XP, streaks, weekly challenges, badges, perk inventory).
- **`LearNova_Web_UI.pdf`** — the admin-facing design: the risk dashboard (at-risk student radar, topic struggle heatmap, class health timeline), intervention management for human admins responding to Mitchy's escalations, and content management for courses/levels/modules/topics.

## Relationship to implementation

[`../mobile-app/`](../mobile-app) implements the App UI spec. The Web UI is not yet implemented — the backend already exposes the data this dashboard needs (`get_admin_risk_radar()`, `get_admin_struggle_map()`, and related RPCs documented in [`../database/`](../database)), but the admin console itself is a planned future phase.

Screenshots from both specs are used in the root README and in `../docs/images/` to give this repository a visual entry point.
