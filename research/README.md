# LearNova — Market Research

The standalone market research findings document: a 351-record dataset validating the problem this platform was built to solve.

## Contents

```
research/
└── LearNova_Market_Research_Findings.pdf
```

## What's in it

This research was built by aggregating data from platform reviews (Coursera, Udemy, Pluralsight), social listening (Egypt-focused Reddit threads), academic papers (2020–2025), industry reports (WEF, ILO, World Bank, Gallup), and real job postings (Wuzzuf — used as the primary source for the skill-cluster data that defines each diploma track's curriculum).

Four findings anchor the platform's design:

| Finding | What it validated |
|---|---|
| **Recruitment inefficiency** | A bad hire costs 30–400% of annual salary depending on seniority; standardized, verifiable skill signals reduce that risk. |
| **The cognitive architecture of digital learning** | Median engagement on educational video drops sharply after 6 minutes, and dropout spikes at structural transitions — directly informing the platform's micro-content and auto-play design. |
| **The hard/soft skills bifurcation** | Technical skills have an ~18-month half-life; 56% of leaders cite weak soft skills as the primary cause of workforce unpreparedness — informing the soft-skills diagnostic track and scoring weight. |
| **The structural failure of career guidance** | 52% of graduates are underemployed a year after graduation; only ~1% of surveyed students in one regional study planned to study a fast-growing technical field — the core justification for an AI-driven recommendation engine over self-selected majors. |

## Relationship to the rest of the repo

This document answers *why* the platform exists. [`../thesis/`](../thesis) covers the full academic writeup including architecture and design validation; [`../backend/`](../backend) and [`../database/`](../database) are where the findings here actually get implemented as scoring models and content structures.
