# LearNova — Docs

Architecture diagrams and shared images referenced across this repository's other READMEs.

## What lives here

```
docs/
├── architecture-diagram.png   System architecture (exported from thesis/LearNova_Thesis.pdf)
└── images/                    Screenshots and visuals used in the root README
```

## Contents

- **`architecture-diagram.png`** — the high-level system diagram showing how the Flutter app, Supabase Edge Functions, Railway backend, and PostgreSQL database connect. Sourced from the full architecture diagram in the project thesis (see [`../thesis/`](../thesis)).
- **`images/`** — app and web UI screenshots used to give the root README a visual entry point. Sourced from the design specifications in [`../design/`](../design).

If you're updating the architecture (adding a new service, changing how a layer connects to another), update the diagram here and reflect the change in the relevant subdirectory README — the goal is that this diagram and the actual deployed system never drift apart.
