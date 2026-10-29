# Did I? — Implementation Plan

This plan builds Did I? to match the Claude Design canvas "Did I? Micro-Logger"
(https://claude.ai/artifact/Ak6phTogoSc8pRCSwqAJYj), and fills the gaps the design leaves. Its artboards are copied
into `design/` in Phase 0 (see `CLAUDE.md` → Design). The architecture follows `CLAUDE.md`.

Each phase ends with an app that builds and passes its tests (run only once the user says yes, as `CLAUDE.md`
asks). It is committed with conventional commits on its own `feature/phase-<n>-<desc>` branch, and it is merged
into `main` and pushed only after the user approves.

- Phase 0 is the foundation.
- Phases 1–2 are the pure core (checks, logs, the day and summary rules) and the design system, with no screens.
- Phases 3–7 build the app's screens: Today, Add & manage checks, photo proof, Detail & History, Settings.
- Phases 8–10 reach outside the app: App Intents, Siri and the Action Button; widgets and the Control Center
  control; reminders.
- Phases 11–12 are the app's icon and name, and the iPad, accessibility and polish pass.

Written 2026-10-30.

---

## Resolved decisions

Each row says where it comes from: the design (`design/<Name>.dc.html`, its markup and `Component` script), the
user (dated), or *proposed, taken without asking* (change any of these by saying so).

| Topic | Decision |
|---|---|
| **Design source** | The canvas above. `Main.dc.html` (Today) is the interactive artboard; its script holds the sample checks, the tile palette, the suggestions and the copy. Port behaviour and copy from it as written. `AddChecks.dc.html` is `Main` with the sheet open. |
| **Platform** | iPhone and iPad, iOS 27.0. Display name **Did I?** (`INFOPLIST_KEY_CFBundleDisplayName`); the project, target and bundle ID keep Did-I. English first, every string in `Localizable.xcstrings`. |
| **Storage** | 2026-10-30, the user: **this device only**, no sync and no account. SwiftData in App Group `group.com.elo.Did-I`, shared by the app and the widget extension; settings in that group's `UserDefaults` suite; photos as files in the group container. |
| **Font** | 2026-10-30, the user: the **design's fonts**, bundled with their OFL licences: Bricolage Grotesque for titles, tile names and big times; DM Sans for everything else. Registered with `CTFontManager` at launch, scaled with Dynamic Type through `Font.custom(_:size:relativeTo:)`, keeping the design's weights. |
| **Theme** | 2026-10-30, the user: a **dark theme** added to the light-only design, derived from its palette (ink ground, raised ink surfaces, the same bright tile colours, lavender muted text), with Appearance **System / Light / Dark** in Settings. Contrast checked in both. The user approves the dark colours from the Phase 2 gallery before Phase 3 builds on them. |
| **Model** | A `Check` (name, kind, order, reminder settings) has many `LogEntry`s (date, source, optional photo). Kinds `door`, `pill`, `stove`, `plug`, `other` pick the icon. Sources `app`, `widget`, `actionButton`, `control`, `siri`, `shortcut`, `notification`; History shows them ("Action Button · photo", "Lock Screen widget", "In the app"). |
| **Today** | From `Main.dc.html`: a check is **done when it has a log today**. The header reads "{done} of {total} today", then "All clear. Nothing to recheck." / "1 left: {name}" / "{n} left to check". A 2-column grid of tiles, an "Add checks" tile, Recent (the latest 3, "See all"), and a floating bar: Today, History, + (Add checks). |
| **Tiles** | From `Main.dc.html`: done tiles fill with the colour at their position, cycling Violet, Sun, Coral, Mint, Sky, Pink, and show the time and "{ago}" ("2h ago · photo"); undone tiles are dashed outlines reading "Tap to log" / "Not yet today". Tapping a tile logs it (again, if done); the camera button logs with a photo, or retakes it. Recent dots take the check's tile colour. |
| **Logging & undo** | From the design: a log appends, never overwrites, and shows a toast ("Logged · {name}", "Photo saved · {name}") with **Undo** for 5 s. Proposed: logging the same check again within **10 s** refreshes that log's time instead of adding one, whatever the source (a double tap, a widget tapped twice); Undo still removes it. A haptic on every log (`.sensoryFeedback`). |
| **Day boundary** | Proposed: "today" starts at midnight, with a **Day starts at** setting (midnight to 5 AM) for the 1 AM door check. Logs are stored as `Date`; "today" and relative times use the current calendar and time zone, so travel and DST just work. |
| **Add checks** | From the design: a sheet of suggestion chips (Windows closed, Car locked, Tap off, Back door locked, Hair tool off, Lights off, Garage shut, Charger unplugged, Heater off), hiding ones already added, and "Something else?" with Add for a custom one; the button reads "Pick at least one" (disabled) / "Add 1 check" / "Add {n} checks". Proposed: a new install starts **empty** (no seeded checks), with an empty state that opens the sheet, and the design's four checks (Front door locked, Pill taken, Stove off, Iron unplugged) lead the suggestions. A suggestion's kind follows its name (door, pill, stove, plug), else `other`. |
| **Manage checks** | Proposed (missing from the design): from a tile's context menu and from Detail: **rename**, **change icon**, **Remove** (with a confirmation dialog; removes its logs and photos); hold and drag tiles to **reorder**. |
| **Detail** | From `Detail.dc.html`: a violet header with Back and Remove, "{state} at {time}" ("Locked at 8:42 AM") and "{day} · {ago}", the latest photo; the "Nudge me when I leave home — Only if it isn't logged yet" switch; the History timeline (time and source) with the log count; **Log it again**. Proposed: the header's verb comes from the kind (Locked, Taken, Off, Unplugged, else "Logged"). |
| **History** | The design's History tab and "See all" link to one check's Detail. Proposed: an **all-checks History** grouped by day, with a filter by check, each row opening its check; **swipe to delete** a wrong log (and its photo). |
| **Photo proof** | Proposed: captured with the camera, downscaled HEIC plus a thumbnail, kept in the app (never the Photos library), shown full screen on a tap, deleted with its log. **Keep photos** 7 days / **30 days** (default) / Forever; logs are kept; stale and orphaned files are swept at launch. `NSCameraUsageDescription`. The Simulator has no camera, so DEBUG builds use `PhotosPicker` there. |
| **Settings** | Proposed root (the design draws only the Action Button page): Appearance, Day starts at, Action Button, Reminders (home location, reassurance), Hide names on Lock Screen, Keep photos, Delete all logs and photos (with a confirmation), About. |
| **Action Button** | From `ActionButton.dc.html`: "A press logs" **Ask me which** (default) or one check; "After a press": **Open camera**, **Strong haptic**. The system assigns the button, not the app: the user picks the app's control or App Shortcut, so the page shows how (Settings › Action Button › Controls › Did I?) and hides on devices without one. Proposed: "Ask me which" uses the intent's check parameter disambiguation, so the press asks "Which check?" without opening the app. |
| **Logged** | From `Logged.dc.html`: "Logged with Action Button", "{name} {state}." ("Door locked."), the time with seconds, **Add a photo as proof**, Undo, Done. Proposed: a log from the Action Button, the control or Siri shows this as an **interactive snippet** (Undo, Add a photo); Add a photo, or Open camera being on, opens the app's camera on that log. When the app is already open, it's the full-screen view. A background intent may not be able to play the strong haptic: Phase 8 checks, and asks the user before dropping or reworking the toggle. |
| **Siri & Shortcuts** | 2026-10-30, the user: App Intents: `CheckEntity` (an `IndexedEntity`, so Spotlight finds "front door"), `LogCheckIntent` ("Log front door in Did I?"), `OpenCheckIntent`, and `LastLogIntent`, which answers **"Did I lock the front door?"** with "Yes, 8:42 AM, 2 hours ago" or "Not yet today". Phrases in an `AppShortcutsProvider`. |
| **Widgets** | From `LockScreen.dc.html`: Lock Screen **circular** (icon and time) and **rectangular** ("DID I?", name, "{time} · {ago}"), each tapping to log again (`Button(intent:)`). 2026-10-30, the user: also Home Screen **small** (one check) and **medium** (four), and a **Control Center control** that logs a check (also assignable to the Action Button). Times use `Text(date, style: .relative)`, so timelines reload only after a log and at day start. Proposed: **Hide names on Lock Screen** (off by default) shows only icon and time, and names are `.privacySensitive()`. Fonts are bundled in the widget too; if they don't render on the Lock Screen, its widgets use the system font. |
| **Two processes, one store** | Proposed: widget and control intents run in the **widget extension's process**, so the app and the extension both write the store. After a write the extension posts a Darwin notification; the app reads the changes through SwiftData history (`fetchHistory`) and also refetches when it becomes active. |
| **Reminders** | 2026-10-30, the user: a **time reminder** per check ("at 9 PM if Pill isn't logged"). Proposed: iOS keeps at most 64 pending local notifications, so reminders are scheduled a day ahead, nearest first, within a budget of 60, and rescheduled on every log, at launch and from a `BGAppRefreshTask`. Logging from anywhere (the app, a widget, a notification) removes that day's pending reminder. Notifications carry a **Log it** action that logs without opening the app. |
| **Leave-home nudge** | From `Detail.dc.html` ("Nudge me when I leave home — Only if it isn't logged yet"). Proposed: home is set in Settings (use current location); a `CLMonitor`, recreated under the same name at every launch, watches it; on leaving, checks with the nudge on and no log today get a notification. The reassurance from `LockScreen.dc.html` ("{name} {state} — {time} / You already checked. You're good.") is optional, off by default. Needs Always location (open question 1). |
| **Tips** | Proposed: TipKit tips, each shown once and none on the empty screen: hold a tile to edit it, add a Lock Screen widget, set up the Action Button. |
| **Permissions** | Proposed: when the camera, location or notifications are refused, the feature's control explains why and links to Settings. Logging never needs a permission. |
| **Code sharing** | Proposed: a `Shared/` synchronized folder in both the app and the widget extension holds the models, stores, rules, intents and design tokens; the widget target gets the app's Swift settings. `Shared/` never imports from `Features/`. |
| **App Store basics** | Proposed: `PrivacyInfo.xcprivacy` (the `UserDefaults` and file-timestamp required reasons). The usage strings (camera, location when in use and always, notifications) are reviewed with the user in Phase 12. |
| **App icon** | From `Logo.dc.html`: a question mark whose dot is a check: a white stroke on Violet `#6B3BFF`, a Sun `#FFD23F` dot, an ink check. The dark icon is the Ink variant, the tinted one the monochrome Lock Screen glyph. At 44 px and below the check drops out. Colourway: open question 2. |

## Open questions

Ask each before the phase that needs it, then move the answer into Resolved decisions with the date.

1. **Before Phase 10**: the leave-home nudge needs **Always** location permission. Is that acceptable, or should
   the nudge (and the Detail switch) be dropped?
2. **Before Phase 11**: the app icon in **Violet** as drawn, or another of the logo's colourways (Coral, Ink, Mint)?

---

## Design inventory

| Surface | Artboard | Phase |
|---|---|---|
| Palette, type, light theme (dark derived) | all artboards | 2 |
| Today: header, tiles, Recent, toast, bottom bar | `Main.dc.html` | 3 |
| Add checks sheet | `Main.dc.html`, `AddChecks.dc.html` | 4 |
| Photo proof (tile camera button, photo badge) | `Main.dc.html`, `Detail.dc.html` | 5 |
| Check detail and its history | `Detail.dc.html` | 6 |
| Action Button settings | `ActionButton.dc.html` | 7 |
| Logged confirmation | `Logged.dc.html` | 8 |
| Lock Screen widgets | `LockScreen.dc.html` | 9 |
| Reassurance notification, leave-home nudge | `LockScreen.dc.html`, `Detail.dc.html` | 10 |
| Logo and app icon | `Logo.dc.html` | 11 |

---

## Phase 0 — Project foundation ✅ Built 2026-10-30 (launched on the simulator; tests compiled, not run)

Branch `feature/phase-0-foundation`.

- Remove the template's `Item` and list. Add `App/` with the composition root. (`ModelContainer.app(inMemory:)` lands
  with the first models in Phase 1; SwiftData has no empty schema.)
- `AppLaunchConfiguration`: an in-memory store and a fresh `UserDefaults` suite when hosted by unit tests
  (`XCTestConfigurationFilePath`) or launched with `-UITests`.
- Create `Shared/` (in the app target for now; the widget joins in Phase 9), so models never have to move.
- The App Group capability, `Localizable.xcstrings`, `PrivacyInfo.xcprivacy`, a `.gitignore` (`xcuserdata/` is
  tracked today: untrack it), and the display name (Did I?).
- Copy the canvas artboards into `design/` (`<Name>.dc.html` plus `canvas.json`).
- A shared `Did-I` scheme (`xcshareddata/`) with both test bundles.

**Done when** the app launches to an empty root view, and the unit and UI test targets run green.

## Phase 1 — Checks, logs & rules

Branch `feature/phase-1-core`. Pure code and stores in `Shared/`, no UI.

- `SchemaV1` with `Check` and `LogEntry` (enums stored as raw strings, `updatedAt` on every write), `CheckKind`,
  `LogSource`, and a migration plan.
- `CheckStore` and `LogStore` protocols and their SwiftData implementations: add, rename, reorder and remove checks;
  log (with the 10 s refresh rule), undo, delete a log; today's logs and the latest per check.
- `Clock` and calendar injection; `DayBoundary` (day start, "today"); `TodaySummary` (done count and the summary
  copy); `RelativeTime` (the design's forms: "Just now", "2h ago", "2h 27m ago", "Yesterday, 10:58 PM");
  `TilePalette`; the suggestion list and name → kind mapping.

**Done when** table tests cover the summary copy, relative times, day boundaries (including DST changes and a day
start after midnight), the 10 s rule and undo, and a write from a second `ModelContainer` on the same file is seen.

## Phase 2 — Design system

Branch `feature/phase-2-design-system`.

- Colour sets for the palette with light and derived dark appearances in `Core/DesignSystem/` (or `Shared/` for
  what the widget uses); Appearance (System / Light / Dark) applied app-wide.
- The bundled fonts with their licences, registered at launch, and a text-style mapping (display and text styles
  on Dynamic Type).
- Components: the check tile (done and undone), the add tile, the chip, the switch row, the round icon button, the
  undo toast, the floating glass tab bar, the timeline row, the section label.
- A DEBUG gallery of every component in light and dark at default and accessibility text sizes.

**Done when** the gallery renders every component, and the user has approved the dark palette from its
screenshots.

## Phase 3 — Today

Branch `feature/phase-3-today`.

- `TodayViewModel` over the stores and rules: tiles, the header and summary, Recent, the toast and undo.
- The Today screen as `Main.dc.html`: the date, title, chip and summary, the grid with tap-to-log and a haptic,
  the Add checks tile (opens a placeholder until Phase 4), Recent with "See all", and the floating bar.
- The empty state for a new install. Refetch when the app becomes active.

**Done when** view-model tests cover logging, undo and the summary with stubs, and a UI test logs a check and undoes
it.

## Phase 4 — Add & manage checks

Branch `feature/phase-4-checks`.

- The Add checks sheet as drawn: chips, "Something else?", the commit button's copy; new checks go to the end.
- A tile's context menu and Detail's actions: rename, change icon, remove (with confirmation); drag to reorder.
- The TipKit tips (hold a tile to edit; the widget and Action Button tips are wired in Phases 8–9).

**Done when** UI tests add two suggestions and a custom check, and rename, reorder and remove one.

## Phase 5 — Photo proof

Branch `feature/phase-5-photos`.

- A camera service behind a protocol (a `PhotosPicker` stand-in in the DEBUG Simulator), the photo store (HEIC
  plus thumbnail in the group container), and log-with-photo / retake from the tile's camera button.
- The photo badge, the full-screen viewer, Keep photos retention, the launch sweep, and the camera-denied state.

**Done when** store tests cover saving, retention and orphan sweeping, and logging with a photo works on a device.

## Phase 6 — Detail & History

Branch `feature/phase-6-history`.

- Detail as `Detail.dc.html`: the header with the latest log and photo, the timeline with sources and the count,
  **Log it again**, and Remove. The nudge switch is shown and stored; it does nothing until Phase 10.
- The all-checks History grouped by day, with the check filter and swipe to delete.

**Done when** UI tests log from Detail and delete a log from History.

## Phase 7 — Settings

Branch `feature/phase-7-settings`.

- The root Settings: Appearance, Day starts at, Action Button, Reminders (placeholder until Phase 10), Hide names on
  Lock Screen, Keep photos, Delete all logs and photos, About.
- The Action Button page as `ActionButton.dc.html`, with the setup help, hidden on devices without the button.

**Done when** each setting persists and takes effect, and a UI test changes the appearance and the day start.

## Phase 8 — App Intents, Siri & the Action Button

Branch `feature/phase-8-intents`. In `Shared/`, so the widget can use them in Phase 9.

- `CheckEntity` (indexed for Spotlight) and its query; `LogCheckIntent`, `OpenCheckIntent`, `LastLogIntent`; the
  `AppShortcutsProvider` phrases.
- The Action Button flow from its settings: one check logs directly; "Ask me which" disambiguates; the interactive
  Logged snippet (Undo, Add a photo); Open camera; the in-app Logged screen.
- Check whether a background intent can play the strong haptic; if not, ask the user.

**Done when** unit tests call each intent's `perform()` against an in-memory store, and Siri and the Action Button
log on a device.

## Phase 9 — Widgets & the Control Center control

Branch `feature/phase-9-widgets`.

- A widget extension target that joins `Shared/` and the App Group, with the app's Swift settings and the fonts.
- Lock Screen circular and rectangular widgets as `LockScreen.dc.html` (interactive, privacy-sensitive, Hide names
  respected); Home Screen small and medium; the Control Center control.
- Timeline reloads after a log and at day start; the Darwin notification and history read so the app sees widget
  writes.

**Done when** each widget renders in its families in both themes (previews), and a widget log appears in the open
app.

## Phase 10 — Reminders

Branch `feature/phase-10-reminders`. Ask open question 1 first.

- Notification permission; per-check time reminders within the 64-notification budget, rescheduled on log, launch
  and background refresh; the **Log it** action.
- The leave-home nudge: home location in Settings, the `CLMonitor` recreated at launch, the nudge and the optional
  reassurance; the location usage strings; the denied states.

**Done when** scheduler tests cover the budget and removal on log (with a stub notification center), and a reminder
and a nudge fire on a device.

## Phase 11 — App icon & name

Branch `feature/phase-11-icon`. Ask open question 2 first.

- The logo rendered from `Logo.dc.html` to `design/DidIAppIcon.svg`, then the app icon (default, dark, tinted) and
  the widget's monochrome glyph.

**Done when** the icon shows on the Home Screen in light, dark and tinted modes.

## Phase 12 — iPad, accessibility & polish

Branch `feature/phase-12-polish`.

- `NavigationSplitView` on regular width (Today beside Detail), landscape on every size class, form sheets on iPad.
- Dynamic Type up to the accessibility sizes (the grid reflows to one column), VoiceOver copy from the design's
  `aria-label`s, Reduce Motion and Reduce Transparency, contrast in both themes, a localization pass.
- Review the usage strings and the privacy manifest with the user.

**Done when** a layout UI test passes on an iPad and at an accessibility text size, and the full suite is green.
