k# Repository guidance

## Project

Back-o-Mat is a Flutter application for browsing bread recipes and planning baking
stages, including durations, temperatures, ingredients, and timers. The package
name is `flutter_back_o_mat`. Native projects exist for Android, iOS, and macOS.

## Code map

- `lib/main.dart`: initializes Flutter, imports bundled recipes, and starts `Backomat`.
- `lib/navigation.dart`: adaptive app frame with retained Recipes, Planner, and Settings navigators.
- `lib/recipes/`: recipe listing widgets.
- `lib/recipe/`: recipe detail and baking views; `item/` contains recipe components
  and `stage/` contains date and timer widgets.
- `lib/planner/`: baking planner widgets.
- `lib/util/`: JSON, duration, and restoration helpers.
- `lib/util/db/`: SQLite persistence and bundled recipe import.
- `assets/recipes/` and `assets/images/`: bundled recipe JSON and photographs,
  registered in `pubspec.yaml`.
- `lib/l10n/`: English and German ARB sources and generated localization classes.
- `test/`: Flutter tests.

## Setup and commands

Run commands from the repository root with Flutter and Dart on `PATH`:

```sh
flutter --version
flutter pub get
flutter gen-l10n
flutter run                    # select an available device
flutter run -d macos           # requires macOS and Xcode setup
```

The project requires Dart `>=3.13.0 <4.0.0` and Flutter `>=3.47.0`. Native macOS plugins use Swift
Package Manager; preserve that integration. Avoid unrelated dependency upgrades
or regenerating platform projects.

For code changes, use the relevant checks:

```sh
dart format <changed-dart-files>
flutter analyze
flutter test
flutter test test/widget_test.dart  # example of running a specific test file
```

Tests cover recipe creation, editing, import adapters, validation, draft rendering,
and mocked extraction. API tests must use mock transport unless a live extraction
has been explicitly initiated with a configured key. Documentation-only changes
do not require Flutter builds or tests.

## Implementation conventions

- Follow `analysis_options.yaml` (`flutter_lints`) and nearby Dart conventions.
  Keep changes focused and format only the files you change.
- Reuse the existing widgets and helpers; introduce dependencies or architectural
  changes only when the task needs them.
- Put translated UI strings in both `lib/l10n/app_en.arb` and
  `lib/l10n/app_de.arb`. Run `flutter gen-l10n` to refresh generated classes;
  do not edit those classes manually. Configuration lives in `l10n.yaml`.
- Register new assets in `pubspec.yaml`. Preserve recipe IDs, JSON structure,
  ingredient references, and units unless deliberately migrating the data.
- Recipes are stored as JSON in `recipes_json_database.db` in the application
  documents directory. Startup imports bundled recipes and skips names already
  present. Editing an asset may therefore not update an existing installation.
- Preserve persisted user data. Schema changes need a database version/migration
  strategy; do not clear the database as a routine fix.
- Startup uses `sqflite` and `path_provider`; tests exercising startup or recipe
  screens may need plugin mocks or database isolation.
- Add or update meaningful tests for changed behavior, especially scheduling,
  duration calculations, JSON handling, and persistence.

## Workspace care

Check `git status` before editing and preserve existing user changes. Avoid
unrelated formatting, dependency lockfile churn, or edits to generated build
outputs (`build/`, `.dart_tool/`, plugin registrants). Do not commit secrets,
machine-specific paths, or application databases. Summarize the changes and
checks run, including anything that could not be verified.

## Recipe authoring

- Shared recipe data and validation live in `lib/recipe/data/`; editor, import,
  scanning, and detail views live in `lib/recipe/editor/`.
- Missing ingredient/stage lists represent drafts, not fatal parse errors.
- New recipes use database-allocated IDs. Do not use source JSON IDs or replace
  existing records during import. Only explicit edits update a selected ID.
- Cover images use app-owned `local:` filenames; never open arbitrary paths from
  imported JSON. Scanning source documents are transient.
- API credentials belong in macOS Keychain via `backomat/keychain`. Never log
  credentials or source documents. All extraction requests need an explicit user
  action, with no automatic billable retries.

## Baking sessions

- `lib/baking/` contains the saved-session model, schedule calculation,
  persistence, and combined baking table. The planner uses these same sessions.
- Database version 2 adds `baking_sessions`; upgrades must preserve recipes and
  prior session progress. Sessions contain immutable-in-use recipe snapshots.
- Schedule from a saved start and explicit stage references. Independent stages
  may run in parallel; dependent stages wait for all actual completions.
- Countdown accuracy comes from persisted deadlines, not accumulated timer ticks.
  View timers only refresh the display and must be disposed. Save state changes
  before showing them as successful; failures retain the last saved state.
- Tests must inject clocks and repositories, never wait for real baking durations
  or mutate application databases. Test min/max ranges, pause/resume, reopening,
  snapshot isolation, dependencies, and migration compatibility.

- `baking_timeline.dart` uses the shared schedule model and a fixed time scale per
  gesture. Preview from an unchanged session copy, clamp durations/dependencies,
  save once on release, and roll back on cancel or persistence errors. Only
  pending steps may move/resize. Table and timeline share actual Table row
  geometry so dependency arrows stay aligned with wrapped instructions.

- Dependency timing diagnostics are derived from the shared schedule: normal
  waiting, waiting beyond the predecessor's maximum window, or overlapping actual
  steps. Recalculate pending descendants, but never rewrite actual timestamps to
  resolve a conflict. New completed-step JSON may include `completedReadyUntil`;
  accept older progress without this optional field. Keep guides thin and limited
  to the selected flexible step, and expose timing warnings as text as well as color.

## Visual style and app frame

- `lib/theme/` defines system-following light/dark themes, semantic colors, shared
  page headers, surfaces, and status badges. Reuse these rather than hard-coded
  colors. Preserve distinct selection, waiting, warning, and conflict indications.
- Desktop sidebar navigation remains visible around feature routes. Push feature
  screens through their nearest Navigator; use the root Navigator for modal
  dialogs. Never reset a section's stack merely to change destinations or resize.
- Only the selected section may handle system Back. Keep editor PopScope discard
  confirmation intact. AI-key settings live under `lib/settings/`.
- Honor inherited TickerMode visibility for visual refresh timers. Cancel hidden
  timers and resume from saved clock timestamps, not accumulated ticks.
- Verify theme contrast, narrow English/German layouts, retained drafts, section
  switching, and countdown continuity when changing navigation or styling.
