# LearNova — Mobile App

The Flutter client. This is the only part of the system a student ever directly interacts with.

## What lives here

```
mobile-app/
├── lib/
│   ├── screens/         Onboarding, diagnostics, lessons, chat, gamification UI
│   ├── services/         Supabase client, API calls to Edge Functions
│   ├── models/           Data models matching the Supabase schema
│   └── widgets/          Shared/reusable UI components
├── assets/
└── pubspec.yaml
```

## Architecture: what this app does and does not talk to

The app holds a Supabase URL and a public anon key — nothing more sensitive. It **never** calls the Railway backend directly, and it never computes XP, exam scores, or diagnostic results client-side. Every privileged action is a call to a Supabase Edge Function, authenticated with the logged-in user's session token:

```
Flutter  →  Supabase Edge Function (verifies session, holds service key)  →  Railway (scoring/AI)
```

This means the app's job is rendering state and collecting input — not deciding what's true. A student can't, for example, edit a network request to grant themselves XP, because the XP write only ever happens server-side, gated behind a re-validated session and (where relevant) duplicate-submission checks.

## Core features implemented in this client

- **Onboarding diagnostics** — five assessments (personality, soft skills, learning style, career interest, cognitive aptitude) that feed the track-assignment engine.
- **Adaptive lesson delivery** — each topic can render as Visual, Auditory, or Textual content depending on the student's calibrated learning style.
- **Mitchy chat** — the AI mentor interface, including hidden structured actions (e.g. "switch to Visual format") parsed from Mitchy's response payload, not just plain text.
- **Gamification** — XP display, daily streaks, weekly challenges (with a countdown to the next available window), perk inventory (Owl of Wisdom hints, Sly Fox 5000 answer eliminators), and badge collection.

## Local setup

```bash
cd mobile-app
flutter pub get
```

Create a `.env` (or use `--dart-define`, depending on how the project is configured) with:

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

Run:

```bash
flutter run
```

## Status

Onboarding and diagnostic flow, adaptive content rendering, and core gamification UI are in active development. Mitchy's full structured-action handling is being built alongside the backend's AI orchestration work.
