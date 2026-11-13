# Flutter Back-o-Mat

A flutter project for having a back-o-mat.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running on macOS

The macOS project uses Swift Package Manager for native Flutter plugins and
requires macOS 12 or later. Use a Flutter SDK with Swift Package Manager support
enabled and Xcode 15 or later. If needed, enable support with
`flutter config --enable-swift-package-manager`.

```sh
flutter pub get
flutter run -d macos
```

Flutter generates the plugin Swift package under `macos/Flutter/ephemeral/`.
CocoaPods is not required for macOS with the current plugins. The iOS project
still has its existing CocoaPods setup.

## Application Documents Directory

On MacOs: `/Users/user/Library/Containers/com.joel.backomat.flutterBackOMat/Data/Documents`

## First Flutter App

https://docs.flutter.dev/get-started/codelab

## Flutter Widgets

https://docs.flutter.dev/development/ui/widgets-intro

### ListTile

https://api.flutter.dev/flutter/material/ListTile-class.html

### Scaffold

https://api.flutter.dev/flutter/material/Scaffold-class.html

### Bottom Navigation Bar

https://api.flutter.dev/flutter/material/BottomNavigationBar-class.html

### Padding

https://api.flutter.dev/flutter/widgets/Padding-class.html

https://api.flutter.dev/flutter/painting/EdgeInsets-class.html

### ListView

https://api.flutter.dev/flutter/widgets/ListView-class.html

### Table

https://api.flutter.dev/flutter/widgets/Table-class.html

https://dartpad.dev/?id=0bc0f378c2722dc94e7a8c583180705e

## Flutter Layouts

https://docs.flutter.dev/development/ui/layout

https://docs.flutter.dev/development/ui/layout/tutorial

https://docs.flutter.dev/codelabs/layout-basics

## Flutter Navigation

https://docs.flutter.dev/cookbook/navigation/navigation-basics

## Flutter JSON and serialization

https://docs.flutter.dev/development/data-and-backend/json

## Flutter Setup on MacOS

https://docs.flutter.dev/get-started/install/macos

## Flutter Resources

https://api.flutter.dev/

https://pub.dev/

## Flutter GitHub Repository

https://github.com/flutter/flutter

## Flutter Packages

https://pub.dev/packages/dotted_border

## Flutter Q&A

https://stackoverflow.com/questions/51638176/under-which-circumstances-textalign-property-works-in-flutter

https://stackoverflow.com/questions/52774921/space-between-columns-children-in-flutter

https://stackoverflow.com/questions/71832067/change-the-bottom-navigation-screen-and-its-index-on-button-press

https://stackoverflow.com/questions/48481590/how-to-set-update-state-of-statefulwidget-from-other-statefulwidget-in-flutter

https://stackoverflow.com/questions/71479979/how-to-assign-a-callback-function-to-a-variable

https://stackoverflow.com/questions/50287995/passing-data-to-statefulwidget-and-accessing-it-in-its-state-in-flutter

https://stackoverflow.com/questions/52048101/how-to-reset-the-base-route-in-my-flutter-app-that-is-pop-any-routes-and-repla

https://stackoverflow.com/questions/15804101/dart-lambda-shortland-function-confusion

https://stackoverflow.com/questions/51053954/how-to-deserialize-a-list-of-objects-from-json-in-flutter

https://stackoverflow.com/questions/51901002/is-there-a-way-to-load-async-data-on-initstate-method

https://stackoverflow.com/questions/67040839/flutter-lateinitializationerror-field-name-has-not-been-initialized

https://stackoverflow.com/questions/53455358/how-to-present-an-empty-view-in-flutter

https://stackoverflow.com/questions/49713189/how-to-use-conditional-statement-within-child-attribute-of-a-flutter-widget-cen

https://stackoverflow.com/questions/66240406/how-to-properly-json-encode-decode-a-duration-field-in-flutter

https://stackoverflow.com/questions/64278595/null-check-operator-used-on-a-null-value

https://stackoverflow.com/questions/50252569/vertical-viewport-was-given-unbounded-height

https://stackoverflow.com/questions/57803737/flutter-renderflex-children-have-non-zero-flex-but-incoming-height-constraints

https://stackoverflow.com/questions/56947046/flutter-for-loop-to-generate-list-of-widgets

https://stackoverflow.com/questions/52053850/flutter-how-to-make-a-column-screen-scrollable

https://stackoverflow.com/questions/45745448/how-do-i-stretch-an-image-to-fit-the-whole-background-100-height-x-100-width

https://stackoverflow.com/questions/57803737/flutter-renderflex-children-have-non-zero-flex-but-incoming-height-constraints

https://stackoverflow.com/questions/51418923/how-to-give-a-dashed-border-in-flutter

https://stackoverflow.com/questions/66041293/how-to-remove-the-outermost-border-lines-of-table-in-flutter-flutter

https://stackoverflow.com/questions/49438433/how-to-flatmap-list-in-dart

https://stackoverflow.com/questions/53455358/how-to-present-an-empty-view-in-flutter

https://stackoverflow.com/questions/54610121/flutter-countdown-timer

https://stackoverflow.com/questions/59819494/how-to-set-align-right-in-table-with-flutter

https://stackoverflow.com/questions/53824755/flutter-dart-how-to-access-a-single-entry-in-a-map-object

https://stackoverflow.com/questions/64092241/the-instance-member-widget-cant-be-accessed-in-an-initializer

https://stackoverflow.com/questions/29182581/global-variables-in-dart

# Dart

https://dart.dev/codelabs/dart-cheatsheet

Announcements about dart can be found on:

https://medium.com/dartlang

# Kotlin

## Kotlin Stackoverflow Resources

https://stackoverflow.com/questions/65715276/a-function-body-must-be-provided-try-adding-a-function-body

## Adding and editing recipes

Recipes are organized into bread families. The recipe list shows each family
once, using its main variant's cover and description. Open a recipe to switch
variants, create an independent copy with a unique variant name, choose the main
variant, or rename the family. Recipe titles may remain the same across variants.

Drag the handle at the right of a recipe row to arrange the start screen manually.
The order is saved automatically per bread family and survives main-variant
changes and restarts. New families are appended at the bottom. Database version
4 introduces these positions, preserving the previous alphabetical order when
upgrading existing installations.

The collapsible **Notes / Notizen** section holds freely named notes with
multiline text. Shared family notes cover advice that applies to every variant;
variant notes belong to the selected recipe. Shared notes have their own editor
and Save action. Variant notes are edited with the recipe. Both support adding,
reordering, and removing notes, with confirmation before discarding edits.

Optional **Preparation recipes / Vorbereitungsrezepte** can be attached in the
recipe editor. Choose an existing, specific variant and the bread step that
uses its result, for example a starter refresh before mixing the dough. Several
different preparations can feed the same step. The preparation stays a separate
recipe and can also be run independently; copying a bread variant copies its links.

When creating a bake, choose the preparations needed for that batch. All start
unchecked, so an already-ready starter requires no extra work. Missing or
incomplete preparations are disabled with an explanation. The entered start time
is the start of all work: independent bread steps may run alongside preparations,
while the consuming step waits for the preparation's final steps to be completed.
Selected recipes appear together in one table/timeline with recipe labels and
dependency connections. Their ingredients, notes, and progress remain separate
snapshots; an independently running preparation's progress is never reused.

This version includes only directly attached preparations and uses their
quantities unchanged. Nested optional preparations are explicitly identified as
excluded. Existing baking sessions resume without another preparation prompt or
changes to their saved choices. Link changes participate in recipe history, and
restoration revalidates links. Self-links, cycles, duplicates, and missing consuming
steps are rejected. Native/bundled imports and scan output never bind imported
local preparation IDs; explicit JSON imports show a notice to reattach those links.
The optional recipe/session JSON fields remain compatible with older records;
this feature does not require another database schema migration.

Each changed save creates a revision, optionally with a change description.
Recipe history and shared-note history are separate. Preview an older revision
before restoring it; restoration creates a new revision and keeps later history.
Restoring a variant does not change shared notes or the main-variant selection.
There is no automatic merging, inheritance, history pruning, or cross-family
movement of variants.

Database version 3 adds families and immutable revision records. Existing recipes
keep their IDs and become their own family's main **Standard** variant, with an
initial history entry. New manual, imported, and scanned recipes create a new
family. Native JSON supports an optional `notes` list of `{title, body}` objects;
family memberships and source IDs are never used to replace local records.

On the Recipes screen choose **Add recipe** to enter a recipe manually, import
app-format JSON or Schema.org Recipe JSON-LD, or scan photo/PDF files. Every
import opens in the editor for review. The pencil in recipe details edits an
existing recipe. Drafts only require a name; add ingredients, named stages, and
minimum/maximum stage durations to enable timed baking. Stages can reference
base ingredients and earlier stages, with optional quantities and notes.

JSON import accepts `.json` and `.jsonld` files up to 2 MB. If a JSON-LD document
contains multiple recipes, choose one. Unparsed Schema.org ingredient lines are
preserved as text; quantities, timings, and stage allocations can be completed
in the editor. Imported recipe IDs never replace local records.

For scanning, open **Settings → AI scanning settings** and save your personal
OpenAI API key in macOS Keychain. Select one PDF or up to ten JPEG/PNG pages of
one recipe, at most 20 MB total. Arrange image pages, then explicitly choose
**Extract recipe**. This sends the selected documents to OpenAI and bills your
API account. Extraction uses `gpt-4.1` with structured output; review all values
and warnings before saving. The app requests no stored API response and does
not retain source documents. Cover images selected in the editor are copied
into the application's documents directory when saving.

The implementation uses macOS file-read/network sandbox entitlements and a
native Keychain bridge. Recipe creation and import are verified on macOS;
mobile scanning and camera capture are outside this release. Credentials are
never embedded in the app or repository.

Regression checks:

```sh
flutter analyze --no-pub lib/recipe/data lib/recipe/editor lib/recipes
flutter test --no-pub
flutter build macos --debug --no-pub
```

## Planning and following a bake

The Planner shows saved baking sessions instead of sample steps. Choose **Plan a
bake**, select a complete recipe, and choose its start date/time. Each addition
creates a separate bake, so several recipes or batches can run in parallel.
Opening baking from a recipe resumes an active session (or the earliest planned
one); it creates a session only when no unfinished bake exists.

The planner defaults to the main variant and offers other baking-ready variants.
New sessions also snapshot shared notes and family/variant names; later note
edits or history restoration do not change an existing bake's instructions.

Each session stores a recipe snapshot, planned start, chosen durations, and
actual step progress. Later recipe edits do not change existing sessions. Stages
that reference earlier stages wait for all of those stages; independent stages
start in parallel. Start-time overrides are lower bounds and cannot bypass a
predecessor. Chosen durations default to each stage's minimum and can be changed
within the recipe's range before starting. The planner's completion window uses
both minimum and maximum durations and updates with actual completions.

The baking view combines instructions, duration/temperature, scheduled start/end,
countdown, and actions in one table. Use **Start**, **Pause**, **Resume**, and
**Mark done**. A dependent stage becomes startable only after its predecessors
are marked done. Expiration shows an overdue countdown; it does not automatically
mark a step complete. Countdowns derive from saved end timestamps, so reopening
or restarting the app preserves elapsed time. Paused time stays paused.

Database version 2 adds `baking_sessions` alongside the existing recipes table.
Removing a session requires confirmation and never deletes its source recipe.

### Interactive baking timeline

Wide baking windows show the step table and timeline together, with shared rows
and selection. On narrower windows, use **Table / Timeline** to switch views.
Dependency arrows connect the stages; selecting a step highlights its links.
Use zoom, earlier/later, and **Fit** to navigate long recipes. The time axis stays
stable after dragging; use **Fit** to recalculate its visible range.

Drag a pending step's bar to change its earliest start, or drag the right edge of
a flexible bar to change its duration within the recipe's allowed range. The
preview recalculates dependent stages immediately; one save happens on release.
Press Escape to cancel before release. Started, paused, and completed steps are
locked against timeline movement. Double-click a pending bar for an exact start
time, or click its resize handle for exact minutes. The table retains the precise
time controls. Save failures restore the last saved schedule.

Timeline bars show only the chosen duration. Selecting a flexible step reveals a
thin minimum/maximum guide, rather than a filled extension box. During dragging,
recalculated steps and their connections are highlighted. Pending successors
move later when a predecessor moves later; predecessors stay in place when a
consumer is delayed. Started steps retain their actual timestamps.

Dashed connections indicate waiting. Amber connections, row icons, tooltips, and
messages identify a consumer scheduled after its predecessor's maximum readiness
window; red connections identify a consumer starting before a predecessor is
ready. The maximum window is based on the predecessor's effective start plus
its recipe maximum duration, accounting for pauses. Readiness information is
saved on new completions so those checks remain accurate after reopening.
Older sessions remain readable. Timing diagnostics do not move actual progress
or alter the recipe automatically.

## Appearance and navigation

Back-o-Mat uses a warm ivory and forest-green light theme, with a coordinated
dark theme selected automatically by the system appearance. Typography, form
fields, buttons, status badges, tables, and timeline colors share one theme.
Timing warnings remain amber and conflicts remain red in both appearances.

Recipes, Planner, and Settings share a centered page frame capped at 1,280
logical pixels, consistent headers and margins, and a content panel that fills
the available height. Lists, tables, and settings scroll within that panel;
header actions wrap below the title on narrow windows.

Windows at least 1,000 logical pixels wide use a persistent desktop sidebar for
Recipes, Planner, and Settings. Smaller windows use bottom navigation. Each
section retains its own routes and unsaved form state, including when resizing
the window. Back navigation continues to ask before discarding edited recipes.
Hidden baking and planner views stop visual refresh timers; countdowns are
recomputed from persisted timestamps when the section becomes visible again.

Settings contains AI-key management, an appearance explanation, and About.
The recipe and baking screens retain their table layouts; the baking timeline
uses the space remaining after the sidebar and provides its table/timeline
switcher when the content area is narrower.

The shared app icon artwork is `assets/branding/app_icon.png`. After replacing
the artwork, run `swift tool/generate_app_icons.swift` from the repository root
on macOS to regenerate the checked-in macOS, iOS, and Android launcher icons.
The exporter preserves opaque iOS artwork and adds transparent rounded corners
and Dock padding for macOS. The sidebar and About screen use the shared artwork.
