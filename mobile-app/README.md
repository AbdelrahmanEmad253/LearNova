# Learnova 🚀

Learnova is an educational Flutter app that guides learners through assessments, personalized recommendations, and a gamified learning experience.

## Highlights ✨

- 🎯 Personalized assessments (cognitive, soft skills, learning style, career guidance)
- 🌌 Space-themed interactive UI with SVG assets and animated transitions
- 🗄️ Supabase-backed session/configuration support and local persistence
- 🧭 Riverpod for state management and modular, feature-first architecture

## Quick start ⚡️

### Prerequisites 🧰

- Flutter SDK (compatible with Dart >=3.0.0)
- Android Studio or VS Code + device/emulator

### Setup 🛠️

```bash
git clone <your-repo-url>
cd "learnova app"
flutter pub get
flutter run
```

### Common developer commands 🧪

- Install dependencies: `flutter pub get`
- Analyze: `flutter analyze`
- Run tests: `flutter test`

## Project entrypoint 🏁

The app bootstrap is in [lib/main.dart](lib/main.dart#L1). It initializes Supabase, shared preferences, and starts the app using `ProviderScope`.

## Architecture & structure 🏗️

High-level layout:

```
lib/
├─ core/        # DI, theme, navigation, shared services (see core/*)
├─ features/    # Feature-based modules (auth, home, assessment, etc.)
└─ assets/      # Images, SVGs, and other static assets
```

- Theme tokens and colors live under `lib/core/theme`.
- Navigation starts from `lib/core/navigation/initial_routing_screen.dart`.
- Authentication and startup logic can be found near `lib/features/auth`.

## Important notes & gotchas ⚠️

- Keep `flutter` asset entries in `pubspec.yaml` synced when adding/moving assets; missing entries cause runtime failures.
- The app uses Supabase; configure environment values in `lib/core/services/supabase/supabase_config.dart` before running in a production environment.
- The project uses Riverpod (`flutter_riverpod`) for state — follow existing provider patterns when adding new global state.
- See [`.github/copilot-instructions.md`](.github/copilot-instructions.md) for in-repo contributor guidelines and project conventions.

## Dependencies (selected) 📦

- `flutter_svg` — SVG support
- `supabase_flutter` — Supabase client
- `flutter_riverpod` / `riverpod` — state management

## Contributing 🤝

1. Fork the repository
2. Create a feature branch
3. Open a PR with a clear description of changes

## License 📜

This repository is distributed under the MIT License.

---
