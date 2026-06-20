# Learnova agent instructions

## Big picture
- This is a Flutter app with a feature-first layout in `lib/features/*` and shared UI/theme code in `lib/core/*`.
- The app is currently UI-first (no backend/service layer yet): most flows are screen-to-screen navigation with local/static models.
- Entry point is `lib/main.dart`; `MyApp` currently launches `HomeScreen` directly (not onboarding/auth).
- Assessment flow is linear and index-driven:
  `AssessmentMapScreen` → `TestingFormatScreen` → `TestDescriptionScreen` → `TestQuestionsScreen` → `TestCompleteScreen` → `FinalResultsSummaryScreen`.
- Shared test metadata now comes from `assessment` clean layers via `GetAssessmentTestsUseCase` and `AssessmentLocalDataSource`.

## Architecture and boundaries
- `lib/core/theme/app_colors.dart` and `lib/core/theme/app_theme.dart` are the source of global colors/theme tokens; prefer reusing these constants.
- `lib/core/widgets/space_scaffold.dart` is the default shell for space background + wave layers; most auth/onboarding/assessment screens should use it.
- Clean architecture is now active in multiple features (`home`, `assessment`, `onboarding`, `auth`) using:
  - `domain/entities`, `domain/repositories`, `domain/usecases`
  - `data/datasources`, `data/models`, `data/repositories`
  - `presentation/screens|widgets`
- `lib/features/home` separates:
  - static data model (`data/models/map_level_model.dart`)
  - UI widgets (`presentation/widgets/*`)
  - screens (`presentation/screens/*`)
- Keep screens depending on use cases (or at minimum domain entities), not on raw inline lists/constants.

## Project-specific coding patterns
- Navigation pattern is imperative with `Navigator.push` / `pushReplacement` + `MaterialPageRoute` (see `login_screen.dart`, `intro_steps_screen.dart`).
- Many layouts are layered `Stack` + `Positioned` over `assets/SpaceBackground.png`; preserve this visual composition pattern.
- Responsive positioning in map/profile screens uses ratio-based coordinates (e.g., `ratioLeft`, `ratioTop` in `HomeScreen`).
- Assets are heavily SVG-based via `flutter_svg`; use `SvgPicture.asset` for new vector assets.
- Keep file placement consistent with feature layers (`presentation`, `domain`, `data`) and naming (`*_repository_impl.dart`, `*_local_data_source.dart`, `get_*_usecase.dart`).

## Workflows
- Install deps: `flutter pub get`
- Lint/analyze: `flutter analyze`
- Run app: `flutter run`
- Run tests: `flutter test`

## Important gotchas
- Keep `pubspec.yaml` asset entries in sync whenever adding/moving assets; missing entries cause runtime load failures.
- `test/widget_test.dart` is still the Flutter template counter test and does not reflect `MyApp`'s current UI flow.
- Asset names include existing typos that are referenced in code (example: `assets/waves/test/carerrtop.svg`); do not “fix” names without updating all references.
- Home map level buttons depend on naming pattern `assets/map/lev<level>.png` used by `MapLevelButton`.

## When making changes
- Prefer minimal, style-matching edits in the target feature instead of cross-cutting refactors.
- Reuse `CustomButton` and `SpaceScaffold` before adding new base UI components.
- If you change assessment step order/count, update navigation logic and indexing assumptions across all assessment screens.