# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

**Did I?** is a native iOS/iPadOS micro-logger for the small things people doubt they did ("Did I lock the front
door? Did I take my pill?"). A *check* is one recurring thing; *logging* it records the time (optionally with a
photo as proof), so the answer is one glance away: in the app, on a Lock Screen widget, or after one press of the
Action Button. Tagline: "tap once, stop wondering".

Phases 0–12 are built and merged; phases 13–18 (categories and the calendar, from the 2026-10-30 canvas update)
are next. See `Plan.md` for which are done. `Plan.md` (written 2026-10-30) holds the resolved decisions, the open questions and the
phases 0–12, built in order; update it as phases finish. Ask about scope beyond it and the design (see **Design**)
rather than inventing it.

The architecture below follows the sibling apps (`../UnitConverters/CLAUDE.md`, `../FinCalculators/CLAUDE.md`,
modelled on `../Papers`) and is the convention to grow into. Use them for architecture only; their product rules
don't apply here.

## Tech stack

| Concern | Choice | Notes |
|---|---|---|
| UI | SwiftUI | `NavigationStack` / `NavigationSplitView` (iPad), not `NavigationView` |
| State | `@Observable` macro | Not `ObservableObject` / `@Published` |
| Targets | `Did-I`, `DidIWidgets` (widget extension, `com.elo.Did-I.Widgets`), `Did-ITests`, `Did-IUITests` | Both apps share `Shared/` and the App Group |
| Persistence | SwiftData | `@Model`, `ModelContainer`, `ModelContext`; on this device only (no CloudKit), in the App Group |
| Sharing | App Group `group.com.elo.Did-I` | One store, settings suite and photo folder for the app and the widget extension |
| Settings | `UserDefaults` (group suite) | Appearance, day start, Action Button, privacy, photo retention, reminders |
| Intents | App Intents | Log / open / "Did I…?" intents, App Shortcuts, Spotlight, the Action Button |
| Widgets | WidgetKit | Lock Screen, Home Screen and a Control Center control, in a widget extension |
| Photos | Camera capture | HEIC files in the group container, never the Photos library |
| Reminders | UserNotifications + Core Location | Time reminders and the leave-home nudge (`CLMonitor`) |
| Tips | TipKit | One-time hints |
| Strings | `Localizable.xcstrings` | From the first view onward |
| Unit tests | Swift Testing | `@Test`, `#expect`, `#require` |
| UI tests | XCTest / XCUITest | Swift Testing doesn't support UI automation |
| Dependencies | Swift Package Manager | No CocoaPods or Carthage |

All of these are in place (phases 0–12).

**Don't add third-party dependencies unless asked.** Prefer first-party frameworks, and if a package seems
necessary, confirm with the user first.

## Project file facts

- **File-system synchronized groups**: any file created under `Did-I/`, `Did-ITests/` or `Did-IUITests/` joins that
  target automatically. Don't edit `project.pbxproj` to add files (adding a new target, such as the widget
  extension, does change it).
- The product module is **`Did_I`** (`@testable import Did_I`); the app type is `Did_IApp`.
- The Info.plist is **generated** (`GENERATE_INFOPLIST_FILE = YES`); add plist keys as `INFOPLIST_KEY_*` build
  settings on the `Did-I` target (Debug and Release).
- Bundle ID `com.elo.Did-I` (team `J8MHDV8383`); deployment target **iOS 27.0**; iPhone and iPad
  (`TARGETED_DEVICE_FAMILY = 1,2`).
- String catalogs are on (`LOCALIZATION_PREFERS_STRING_CATALOGS`, `STRING_CATALOG_GENERATE_SYMBOLS` on the app
  target). Put user-facing strings in `Localizable.xcstrings` (not created yet).
- Build settings that change how code compiles: `SWIFT_VERSION = 5.0`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`,
  `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` (each file must import every module it uses), and on the
  app target only, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.

## Build, run, and test

Scheme: `Did-I`. Run on the **iOS 27.0** runtime, on the simulator named **"iPhone 18 Pro"**
(`81648FB0-3C41-433C-8562-DED843609C7A`). The sibling apps use "iPhone 17 Pro" (Papers, EloBill), "iPhone 17"
(FinCalculators) and "iPhone Air" (UnitConverters), and sharing a simulator makes both sessions' UI tests fail, so
don't use those here. Always pin `OS=27.0` or use the UDID (`xcrun simctl list devices available`).

Preferred: the XcodeBuildMCP CLI (`xcodebuildmcp`, see the `xcodebuildmcp-cli` skill), with arguments passed as `--json`:

```bash
xcodebuildmcp simulator build-and-run --json '{"projectPath":"Did-I.xcodeproj","scheme":"Did-I","simulatorId":"<UDID>"}'
xcodebuildmcp simulator test --json '{"projectPath":"Did-I.xcodeproj","scheme":"Did-I",
  "simulatorId":"<UDID>","extraArgs":["-maximum-parallel-testing-workers","2"]}'
```

Raw `xcodebuild`:

```bash
# Build
xcodebuild build -scheme Did-I -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0'

# Unit + UI tests
xcodebuild test -scheme Did-I -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  -maximum-parallel-testing-workers 2

# Unit tests only
xcodebuild test -scheme Did-I -only-testing:Did-ITests \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -maximum-parallel-testing-workers 2

# Single test (Swift Testing: Target/SuiteType/testFunction())
xcodebuild test -scheme Did-I -only-testing:'Did-ITests/AppLaunchConfigurationTests/uiTestLaunchUsesMemory()' \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0'
```

`xcodebuild` clones the simulator once per parallel worker, so always cap it with
`-maximum-parallel-testing-workers 2` (or `-parallel-testing-enabled NO`).

To look at one screen without tests, build for the simulator, install with `xcrun simctl install`, launch with
`xcrun simctl launch --terminate-running-process <UDID> com.elo.Did-I -UITests -SeedSample -Open detail`, and take
`xcrun simctl io <UDID> screenshot`. The Debug-only launch arguments (`AppLaunchConfiguration`):

- `-UITests`: an in-memory store, a fresh `UserDefaults` suite, TipKit tips hidden.
- `-SeedSample`: the design's four checks, three logged this morning (only into an empty store).
- `-Open <screen>`: `addChecks`, `history`, `settings`, `actionButton`, `reminders`, `detail` (the first check),
  `logged` (the newest log).
- `-Gallery` / `-GalleryControls`: the design-system gallery (tiles first, or the controls).
- `-Appearance light|dark`: forces the theme.

`xcrun simctl ui <UDID> appearance dark` and `xcrun simctl ui <UDID> content_size accessibility-extra-large` switch
the system theme and text size. For the iPad split view use the iOS 27.0 "iPad Air 11-inch (M4)"
(`75DF238D-64A3-4D6E-91A3-287ADE75AD09`). Widgets, Siri, the Action Button, the camera, notifications and leaving
home can't be driven from the command line; check those on a device.

**Don't run tests on the simulator by default.** Building is fine, but ask the user before running any unit or UI
tests (a single test included), and run them only when they say yes.

## Implementation guidelines

### Design: Apple's Human Interface Guidelines

- Build with standard SwiftUI components (`List`, `NavigationStack` / `NavigationSplitView`, `.sheet` with detents,
  `.toolbar`, `.swipeActions`, `.contextMenu`, `Toggle`) before custom ones. Customize through modifiers and styles,
  never by rebuilding what the system already gives. The check tiles are the design's own and are custom by
  necessity.
- Use the iOS 27 conventions: Liquid Glass for floating chrome (`.glassEffect`, glass button styles), sheets with
  detents for short tasks (Add checks), and confirmation dialogs for destructive actions (Remove a check).
- Text uses system text styles. Leave at least a 44 × 44 pt hit target, use SF Symbols, and follow the platform's
  spacing and safe areas.
- Accessibility is part of done: VoiceOver labels, values and hints (the design's `aria-label`s are the copy to
  use); Dynamic Type up to the accessibility sizes, with layouts that reflow; Reduce Motion and Reduce Transparency
  respected; contrast checked in both themes.
- Respect platform behaviour: standard back navigation and swipe gestures, state restored where users expect it,
  and haptics only for meaningful moments (`.sensoryFeedback`; logging a check is one).
- Lay out for every size class, from the smallest iPhone to iPad full screen, landscape included. The design is
  drawn for a 390 pt phone only; don't assume a fixed screen size.

### Performance and reuse

- **Keep view updates cheap.** Small views with narrow inputs, stable `id`s in `ForEach`, and no work in `body` (no
  sorting logs, computing "2h ago" or formatting dates there). Precompute in the view model, and cache formatters.
- **Make lists lazy.** History grows without bound; use `List` / `LazyVStack`.
- **Reuse before writing.** Check `Core/DesignSystem/Components/` and `Core/` for an existing component, style or
  helper first. A UI piece used twice becomes a design-system component, and logic used by two features (or by the
  app and the widget) moves to `Core/`.
- **Design for testability.** "Done today", the summary line, relative times and the tile palette are pure; stores
  and services (camera, location, notifications) sit behind protocols and are injected, so stubs replace them in
  tests and previews.

## Architecture

MVVM with one-way dependencies:

```
View  →  ViewModel  →  Store / Service
```

Views never reach past their view model, and services never import SwiftUI.

### Core of the app: checks and logs

```
CheckCategory (@Model)  ──<  Check (@Model)  ──<  LogEntry (@Model)
 name, icon, colour,     name, kind, order,    date, source (app / widget / Action Button),
 repeat rule, reminder   leave-home nudge      optional photo
        │
        └─→ DayAgenda (a day + a filter): due categories, done states, progress, Coming up
              ─→ TodayViewModel ─→ TodayView (7-day strip, sections, tiles)
            Widgets / App Intents read and write the same store (App Group)
```

Phases 0–12 built a flat list of checks; phases 13–18 of `Plan.md` add categories and the calendar. These are the
design's rules, ported from `Main.dc.html`'s and `NewCategory.dc.html`'s scripts; `Plan.md`'s **Categories &
calendar** table is the authority:

- **Every check belongs to one category**, which has an icon, a colour, a repeat rule (daily, weekly, every 2
  weeks, monthly, yearly, on a date) and an optional "Remind me at" time. **Daily** always exists.
- **A check is "done" on a day when it has a log in that day**; a category shows on the days its rule makes it due.
  Today's progress bar reads "{done} of {total} done" with "{n} left" / "All clear" / "Free day" / "Upcoming".
- **Logging appends a log**, never overwrites; tapping a done tile logs it again, but only on today. The camera
  button on a tile logs with a photo ("Photo saved · {name}"), or retakes it. Every log shows an undo toast for
  5 seconds that restores the state before it.
- **Tiles**: done tiles fill with the palette colour at the check's position in the whole list (cycling Violet,
  Sun, Coral, Mint, Sky, Pink) and show the time; undone tiles today are dashed outlines reading "Tap to log";
  tiles on a later day read "Upcoming" and can't be logged.
- **Add sheet**: "Add to" a category, suggestion chips (hiding names already used) and/or a custom one
  ("Something else?" + Add); the button reads "Pick at least one" (disabled) / "Add {n} tasks to {Category}". A
  check's kind (its icon) follows its name.
- **Log sources are part of the data**: history rows read "Action Button · photo", "Lock Screen widget",
  "In the app", so every log records where it came from.

### Directory structure

The convention on disk: `App/` (composition root), `Core/<area>/` (e.g. `Checks/`, `Formatting/`, `Settings/`,
`Persistence/` with `Models/` and `Stores/`, `DesignSystem/Components/`), `Features/<Feature>/` with `Views/`,
`ViewModels/` and `Models/`, `Debug/` (DEBUG-only) and `Resources/`. Create a folder when its first file lands; the
synchronized groups pick it up. `Did-ITests/` mirrors `Did-I/`, with shared helpers in `Did-ITests/Support/`.

`Shared/` is a synchronized folder in **both** the app and the `DidIWidgets` extension: the models, stores,
day and summary rules, App Intents and the design tokens the widget uses. It must not import from `Features/` or
use app-only APIs (the extension builds with `APPLICATION_EXTENSION_API_ONLY`). `DidIWidgets/` holds only the widget and control views; its Info.plist and entitlements are in `Config/`. Intents live in `Shared/Intents/` and read `IntentServices.shared`, which the app replaces at launch with its own store so intents and screens share one context.

### Placement rules (under `Did-I/`)

- A type used by one feature lives in that feature's folder. Once two or more features use it, move it to `Core/`.
- Persisted `@Model` types live in `Core/Persistence/Models/` so the schema has one home. Anything the widget
  extension or intents also compile must not depend on `Features/`.
- `Core/DesignSystem/Components/` must not import anything from `Features/`.

### View models

- `@Observable` classes (not `ObservableObject`), one per screen, named `<Screen>ViewModel`.
- The app target is MainActor by default, so don't add `@MainActor` or `MainActor.run` to view models.
- Mutable state is `private(set)` and changes only through methods.
- Inject dependencies through the initializer as protocol types. Never construct a concrete service inside a view model.

### Views

- Views are SwiftUI only: no business logic and no model mutations. They may read with `@Query`.
- Own view models with `@State`, and use `.task {}` for lifecycle async work. A `@State` default runs on every
  `init`, so build anything expensive lazily.
- Split bodies longer than about 40 lines into child views or private properties. Never use `AnyView`.
- Previews that use DEBUG-only helpers go inside `#if DEBUG`, because Release builds compile previews too.

### SwiftData

- Build one app container in a single place (e.g. `ModelContainer.app(inMemory:)`) with every `@Model` listed in
  one schema list; a model missing from that list isn't stored. Tests and previews use in-memory containers.
- **Stores are the only code that inserts, updates or deletes models.** Every write sets `updatedAt`.
- `ModelContext` isn't `Sendable`, so background writes (e.g. from an App Intent) go through a `@ModelActor`.
- **Two processes write the store.** Widget and control intents run in the widget extension, so never assume the
  app's context is the only writer: the app picks up outside writes through SwiftData history (signalled by a
  Darwin notification) and refetches when it becomes active.
- Keep models `final` and store enums (check kind, log source) as raw strings. Store photos as files or with
  `@Attribute(.externalStorage)`, not inline blobs.
- The schema is versioned: `SchemaV1` holds frozen copies of the phase 0–12 models, and the app's `Check`,
  `LogEntry` and `CheckCategory` are typealiases of `SchemaV2`'s. A schema change adds `SchemaV3` with copies of the
  models and a stage in `DidIMigrationPlan`, and never edits an earlier version's models. Daily has a fixed id
  (`CategoryDefaults.dailyID`).

### Concurrency

- Everything unannotated in the app target is main-actor isolated. Pure logic (done-today, summary, relative time)
  is `nonisolated` so tests, widgets and intents can use it anywhere. Values crossing an isolation boundary must be
  `Sendable`.
- Test targets are **not** MainActor-by-default. Mark suites `@MainActor` when they touch app types.
- Use `async/await`. Don't add `DispatchQueue`, completion handlers or Combine, and don't silence warnings with
  `@unchecked Sendable` or `nonisolated(unsafe)`.

### Testing

- `Did-ITests` is hosted by the app (`TEST_HOST`), so the app launches with its real on-disk container while unit
  tests run. When the container moves to `App/`, have it switch to an in-memory store when
  `XCTestConfigurationFilePath` is set.
- Use Swift Testing (`@Test`, `#expect`, `#require`, `arguments:` tables for the summary and relative-time rules).
  Each test creates its own in-memory `ModelContainer`, injects a fixed clock and calendar, and injects stubs into
  view models. Don't test view bodies. Nothing reads `Date()` or `Calendar.current` directly where "today" or a
  relative time matters; it goes through the injected clock and calendar.
- `Debug/` code is wrapped in `#if DEBUG` and its strings aren't localized; don't add them to the string catalog.
- A UI test can fail on a cloned simulator with `kAXErrorServerNotFound`. That's the simulator, not the test:
  rerun `-only-testing:Did-IUITests -parallel-testing-enabled NO` before chasing it.
- `Did-IUITests` uses XCUITest. Every element a test touches gets
  `.accessibilityIdentifier("feature.element")`; don't query by visible text. Use `waitForExistence(timeout:)` and
  never `sleep()`. Give UI tests a `-UITests` launch argument (Debug only) that uses an in-memory store and a fresh
  `UserDefaults` suite seeded with the design's sample checks.

### Conventions

- Name files after their primary type. Capability protocols end in `-ing`/`-able`, and booleans read as assertions
  (`isDoneToday`).
- No force-unwraps, `try!` or force casts outside tests.
- Use conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `chore:`, `docs:`) and branch names
  `feature/<desc>` or `fix/<desc>`.

### Phase workflow

- **One branch per `Plan.md` phase**, created from an up-to-date `main` before any code:
  `feature/phase-<n>-<desc>` (`Plan.md` names each phase's branch). Commit in small conventional commits on it.
- **When a phase is complete** (its "Done when" is met and the full test suite passes), stop and **ask the user
  whether to merge it into `main` and push**. Never merge or push without that answer. On a yes: merge
  `--ff-only` when possible, push `main` if the answer includes it, delete the phase branch, and mark the phase
  done in `Plan.md` with the date.
- Before a phase that depends on one of `Plan.md`'s open questions, ask it, then move the answer into Resolved
  decisions with the date.

## Design

The source of truth is the Claude Design canvas "Did I? Micro-Logger":
https://claude.ai/artifact/Ak6phTogoSc8pRCSwqAJYj (open it to see the artboards rendered and working). Its artboards
are `project/<Name>.dc.html` there; read them with the Artifact tool (`action: "read"`, `path`). Phase 0 copies them
into `design/` (outside the synchronized groups, never bundled); they don't render locally, because `support.js`
isn't in the export, so read them as source. If the canvas changes, re-copy them rather than editing `design/`.

- **`Main.dc.html` ("Today") is the app's home** and the interactive artboard (redesigned 2026-10-30): the date,
  the "Did I?" title, a 7-day strip from today (dots for non-daily categories due), category filter chips and "New
  category", a sticky progress bar, one section per due category (3-column tiles plus "Add task"), "Nothing due",
  "Add checks", "Coming up", the undo toast, a floating bottom bar (Today with a progress ring / History / + Add),
  and the Add sheet with "Add to" categories. Its script holds the sample categories and tasks, the repeat rules,
  the tile palette, the suggestions and the copy. Port behaviour and copy from it as written. `AddChecks.dc.html`
  is `Main` with the sheet open.
- **`NewCategory.dc.html`**: the New category page: a preview card, name, icon grid, colour swatches, repeat
  (with weekday, day-of-month or date), the tasks list, "Remind me at", and "Create category".
- **`Detail.dc.html` (Check detail)**: violet header with back and Remove, "Locked at {time}" and "{day} · {ago}",
  the latest photo; a "Nudge me when I leave home — Only if it isn't logged yet" switch; the History timeline
  (time and source) with the log count; a "Log it again" button.
- **`LockScreen.dc.html`**: circular widgets (icon and time) and a rectangular one ("DID I?", name, "{time} · {ago}"),
  each tappable to log again, plus a notification "Front door locked — 8:42 AM / You already checked. You're good."
- **`Logged.dc.html`**: the confirmation after an Action Button press ("Logged with Action Button", "Door locked.",
  the time with seconds), with "Add a photo as proof", Undo and Done.
- **`ActionButton.dc.html`** (Settings › Action Button): "A press logs" either "Ask me which" (a quick picker) or one
  check straight away; "After a press": Open camera, Strong haptic.
- **Visual language**: its own palette, not system colours. Cream ground `#FFF6EA`, ink `#17142A`, muted text
  `#5C5670`, Violet `#6B3BFF` (brand), Sun `#FFD23F`, Coral `#FF7A59`, Mint `#2FD4A7`, Sky `#5BC0FF`, Pink
  `#FF8AD8`, deep violet `#2A1670`, lavender `#E3DAFF`, lines `#D9D4EA`, disabled `#B9B2CC`, sand `#EDE6D8`, link
  `#4B22E0`. Large radii (tiles 28, cards 18, pills fully round). Port these as asset-catalog colour sets under
  `Core/DesignSystem/` (or `Shared/` for what the widget uses) and use those names, never raw hex in views. The design
  is light-only; the dark appearances are derived from it (the user's choice), and the user approves them before
  screens are built on them. The app uses the **design's fonts** (the user's choice), bundled: Bricolage Grotesque
  for display and DM Sans for text, both scaled with Dynamic Type (`Font.custom(_:size:relativeTo:)`), never fixed
  sizes.
- **App icon** (`Logo.dc.html`): a question mark whose dot is a check. White stroke on Violet, a Sun dot, an ink
  check; variants on Sun, Dark (Ink) and Light (white), and a monochrome Lock Screen glyph. At 44 px and below the
  check drops out.
- Where the design and `Plan.md` disagree, `Plan.md`'s Resolved decisions win.
