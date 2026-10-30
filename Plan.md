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
- Phases 13–18 follow the canvas update of 2026-10-30: Today becomes a **7-day calendar of categories**, and
  checks are grouped into **categories** with their own icon, colour, repeat schedule and reminder (see
  **Categories & calendar** below). Phase 13 is the core, 14 the components, 15 the new Today, 16 category
  management, 17 the reminders, intents and widgets that follow categories, and 18 the polish pass.

Written 2026-10-30; phases 13–18 added the same day after the canvas changed.

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
| **Font files** | 2026-10-30, while building: static instances cut from the Google Fonts variable files (Bricolage Grotesque SemiBold, Bold at opsz 32 and ExtraBold at opsz 72; DM Sans Regular, SemiBold, Bold at opsz 14), in `Shared/Resources/Fonts/` with their OFL licences, registered per process with `CTFontManager`. |
| **Dark palette** | Proposed (2026-10-30), pending the user's sign-off: ground `#14111F`, surface `#221E33`, sand and chrome `#2E2944`, ink (text) `#FFF6EA`, muted `#B9B2CC`, lines `#3A3452`, link `#B3A1FF`; the six tile colours, violet header and lavender stay as in light. Colour sets live in `Shared/DesignSystem/Palette.xcassets`. |
| **Theme** | 2026-10-30, the user: a **dark theme** added to the light-only design, derived from its palette (ink ground, raised ink surfaces, the same bright tile colours, lavender muted text), with Appearance **System / Light / Dark** in Settings. Contrast checked in both. The user approves the dark colours from the Phase 2 gallery before Phase 3 builds on them. |
| **Model** | A `Check` (name, kind, order, reminder settings) has many `LogEntry`s (date, source, optional photo). Proposed (2026-10-30, while building): kinds `door`, `car`, `garage`, `window`, `tap`, `light`, `pill`, `stove`, `plug`, `other` pick the SF Symbol, so every suggestion gets its own icon; a name's keywords pick the kind. Sources `app`, `lockScreenWidget`, `homeScreenWidget`, `actionButton`, `control`, `siri`, `shortcut`, `notification`; History shows them ("Action Button · photo", "Lock Screen widget", "In the app"). The state a log confirms comes from the name's last word ("Front door locked" → "Locked at 8:42 AM"), else "Logged". Stores hand out value records (`CheckRecord`, `LogRecord`), never models. |
| **Today** | *Superseded by Categories & calendar (phase 15).* From `Main.dc.html`: a check is **done when it has a log today**. The header reads "{done} of {total} today", then "All clear. Nothing to recheck." / "1 left: {name}" / "{n} left to check". A 2-column grid of tiles, an "Add checks" tile, Recent (the latest 3, "See all"), and a floating bar: Today, History, + (Add checks). |
| **Tiles** | *Superseded by Categories & calendar (phases 14–15); the colour cycle and the photo button stay.* From `Main.dc.html`: done tiles fill with the colour at their position, cycling Violet, Sun, Coral, Mint, Sky, Pink, and show the time and "{ago}" ("2h ago · photo"); undone tiles are dashed outlines reading "Tap to log" / "Not yet today". Tapping a tile logs it (again, if done); the camera button logs with a photo, or retakes it. Recent dots take the check's tile colour. |
| **Logging & undo** | From the design: a log appends, never overwrites, and shows a toast ("Logged · {name}", "Photo saved · {name}") with **Undo** for 5 s. Proposed: logging the same check again within **10 s** refreshes that log's time instead of adding one, whatever the source (a double tap, a widget tapped twice); Undo still removes it. A haptic on every log (`.sensoryFeedback`). |
| **Relative times** | Proposed (2026-10-30): "Just now" under a minute, "{m}m ago", "{h}h ago" / "{h}h {m}m ago", "{d}d ago"; the design's mock times mix these, so one rule applies everywhere. |
| **Day boundary** | Proposed: "today" starts at midnight, with a **Day starts at** setting (midnight to 5 AM) for the 1 AM door check. Logs are stored as `Date`; "today" and relative times use the current calendar and time zone, so travel and DST just work. |
| **Empty state** | *Kept for a store with no checks at all; "Nothing due" covers an empty day (phase 15).* Proposed (2026-10-30): "Nothing to check yet" with "Add the things you double-check — the front door, the stove, a pill. Then one tap each time, and you’ll never have to wonder." and an Add checks button. |
| **Add checks** | *Superseded by Categories & calendar (phase 16): the sheet gains "Add to" and new copy.* From the design: a sheet of suggestion chips (Windows closed, Car locked, Tap off, Back door locked, Hair tool off, Lights off, Garage shut, Charger unplugged, Heater off), hiding ones already added, and "Something else?" with Add for a custom one; the button reads "Pick at least one" (disabled) / "Add 1 check" / "Add {n} checks". Proposed: a new install starts **empty** (no seeded checks), with an empty state that opens the sheet, and the design's four checks (Front door locked, Pill taken, Stove off, Iron unplugged) lead the suggestions. A suggestion's kind follows its name (door, pill, stove, plug), else `other`. |
| **Manage checks** | Proposed (missing from the design): from a tile's context menu (Details, Rename, Change icon, Move earlier / later, Remove) and from Detail: **rename** (an alert), **change icon** (a sheet of the ten kinds), **Remove** (a confirmation naming how many logs go with it; removes its logs and photos); drag a tile onto another to **reorder**. Move earlier / later is the VoiceOver-friendly way. |
| **Detail** | From `Detail.dc.html`: a violet header with Back and Remove, "{state} at {time}" ("Locked at 8:42 AM") and "{day} · {ago}", the latest photo; the "Nudge me when I leave home — Only if it isn't logged yet" switch; the History timeline (time and source) with the log count; **Log it again**. Proposed: the header's verb comes from the name's last word (Locked, Taken, Off, Unplugged, else "Logged"), and the header takes the check's tile colour (violet for the first check, as drawn). An Edit menu beside Remove renames or re-icons; the timeline shows the latest 50 logs, with "See all in History" beyond that; hold a timeline row to delete it. |
| **History** | The design's History tab and "See all" link to one check's Detail. Proposed: an **all-checks History** grouped by day, with a filter by check, each row opening its check; **swipe to delete** a wrong log (and its photo). |
| **Photo proof** | Proposed: captured with the camera, downscaled HEIC plus a thumbnail, kept in the app (never the Photos library), shown full screen on a tap, deleted with its log. **Keep photos** 7 days / **30 days** (default) / Forever; logs are kept; stale and orphaned files are swept at launch. `NSCameraUsageDescription`. The Simulator has no camera, so DEBUG builds offer a generated sample photo there (2026-10-30, while building: simpler and deterministic for UI tests than `PhotosPicker`). A retake replaces today's photo on the same log; Undo restores the old one. |
| **Settings** | Proposed root (the design draws only the Action Button page), styled like it (round back button, uppercase section labels, white cards): Appearance, Day starts at, Action Button, Reminders (home location, reassurance), Hide names on Lock Screen, Keep photos, Delete (logs and photos, or everything including checks, after a confirmation), About. The Action Button row shows on iPhone only; there's no API for the button, so the page's help goes by model (iPhone16,1 and later have it) and otherwise points to the Control Center control. |
| **Action Button** | From `ActionButton.dc.html`: "A press logs" **Ask me which** (default) or one check; "After a press": **Open camera**, **Strong haptic**. The system assigns the button, not the app: the user picks the app's control or App Shortcut, so the page shows how (Settings › Action Button › Controls › Did I?) and hides on devices without one. Proposed: "Ask me which" uses the intent's check parameter disambiguation, so the press asks "Which check?" without opening the app. |
| **Logged** | From `Logged.dc.html`: "Logged with Action Button", "{name} {state}." ("Door locked."), the time with seconds, **Add a photo as proof**, Undo, Done. Proposed: a log from the Action Button, the control or Siri shows this as an **interactive snippet** (Undo, Add a photo); Add a photo, or Open camera being on, opens the app's camera on that log. When the app is already open, it's the full-screen view. A background intent may not be able to play the strong haptic: Phase 8 checks, and asks the user before dropping or reworking the toggle. |
| **Strong haptic (checked)** | 2026-10-30, while building: an intent running in the background has no way to play a haptic, so the switch applies when the Logged screen shows in the app (Open camera on, or Add a photo from the card); the Action Button's own click is the haptic otherwise. **Ask the user** whether to keep the switch as that, or drop it. |
| **Intents (built)** | 2026-10-30: `LogCheckIntent`, `LastLogIntent`, `ActionButtonPressIntent` (background, continuing in the app only when Open camera is on), `OpenCheckIntent`, and hidden `WidgetLogIntent`, `UndoLogIntent`, `OpenLoggedIntent`, `LoggedSnippetIntent` (the interactive card, iOS 26 snippet intents). Phrases: "Did I? {check}", "Ask Did I? about {check}", "Log {check} in Did I?", "Log with Did I?". Intents read `IntentServices.shared`, which the app points at its own store. |
| **Siri & Shortcuts** | 2026-10-30, the user: App Intents: `CheckEntity` (an `IndexedEntity`, so Spotlight finds "front door"), `LogCheckIntent` ("Log front door in Did I?"), `OpenCheckIntent`, and `LastLogIntent`, which answers **"Did I lock the front door?"** with "Yes, 8:42 AM, 2 hours ago" or "Not yet today". Phrases in an `AppShortcutsProvider`. |
| **Widgets** | From `LockScreen.dc.html`: Lock Screen **circular** (icon and time) and **rectangular** ("DID I?", name, "{time} · {ago}"), each tapping to log again (`Button(intent:)`). 2026-10-30, the user: also Home Screen **small** (one check) and **medium** (four), and a **Control Center control** that logs a check (also assignable to the Action Button). Times use `Text(date, style: .relative)`, so timelines reload only after a log and at day start. Proposed: **Hide names on Lock Screen** (off by default) shows only icon and time, and names are `.privacySensitive()`. Fonts are bundled in the widget too; if they don't render on the Lock Screen, its widgets use the system font. |
| **Widgets (built)** | 2026-10-30: `CheckWidget` (configurable: choose a check, else the first) for Lock Screen circular and rectangular and Home Screen small; `ChecksOverviewWidget` (medium, the first four); `LogCheckControl` (Control Center and the Action Button), whose logs read "Action Button or Control Center" since the two can't be told apart. Timelines hold now and the next day start. Target `DidIWidgets` (`com.elo.Did-I.Widgets`), with `Shared/` and the App Group. |
| **Two processes, one store** | Proposed: widget and control intents run in the **widget extension's process**, so the app and the extension both write the store. After a write the extension posts a Darwin notification; the app reads the changes through SwiftData history (`fetchHistory`) and also refetches when it becomes active. |
| **Reminders** | *Superseded: reminders move to categories (2026-10-30, the user; phase 17). The budget, rescheduling and Log it rules carry over.* 2026-10-30, the user: a **time reminder** per check ("at 9 PM if Pill isn't logged"). Proposed: iOS keeps at most 64 pending local notifications, so reminders are scheduled a day ahead, nearest first, within a budget of 60, and rescheduled on every log, at launch and from a `BGAppRefreshTask`. Logging from anywhere (the app, a widget, a notification) removes that day's pending reminder. Notifications carry a **Log it** action that logs without opening the app. |
| **Reminders (built)** | *Superseded in phase 17: the check page's reminder row goes; Settings › Reminders lists categories.* 2026-10-30: each check's page has "Remind me if it isn’t logged" (9 PM when turned on, then any time); Settings › Reminders shows notification access, home (set to where you are, within 150 m; move or forget), "Tell me when I’m good", and which checks remind or nudge. Notifications carry **Log it** (logs without opening, source "Notification"); a tap opens the check. A background app refresh (`com.elo.Did-I.reminders`) reschedules at the day change. |
| **Leave-home nudge** | From `Detail.dc.html` ("Nudge me when I leave home — Only if it isn't logged yet"). Proposed: home is set in Settings (use current location); a `CLMonitor`, recreated under the same name at every launch, watches it; on leaving, checks with the nudge on and no log today get a notification. The reassurance from `LockScreen.dc.html` ("{name} {state} — {time} / You already checked. You're good.") is optional, off by default. Needs Always location (open question 1). |
| **Tips** | Proposed: TipKit tips, each shown once and none on the empty screen: hold a tile to edit it, add a Lock Screen widget, set up the Action Button. |
| **Permissions** | Proposed: when the camera, location or notifications are refused, the feature's control explains why and links to Settings. Logging never needs a permission. |
| **Code sharing** | Proposed: a `Shared/` synchronized folder in both the app and the widget extension holds the models, stores, rules, intents and design tokens; the widget target gets the app's Swift settings. `Shared/` never imports from `Features/`. |
| **App Store basics** | Proposed: `PrivacyInfo.xcprivacy` (the `UserDefaults` and file-timestamp required reasons). The usage strings (camera, location when in use and always, notifications) are reviewed with the user in Phase 12. |
| **Polish (built)** | 2026-10-30: regular width shows Today or History beside the chosen check (`NavigationSplitView`, both columns visible); the violet tile's secondary text is `#F1ECFF` (4.9:1 on violet, the design's `#E3DAFF` was 4.3:1); toasts are announced to VoiceOver and fade instead of sliding with Reduce Motion. |
| **App icon** | From `Logo.dc.html`: a question mark whose dot is a check: a white stroke on Violet `#6B3BFF`, a Sun `#FFD23F` dot, an ink check. The dark icon is the Ink variant, the tinted one the monochrome Lock Screen glyph. At 44 px and below the check drops out. Colourway: open question 2. |

## Categories & calendar (canvas update, 2026-10-30)

The canvas changed after phases 0–12 were built: `Main.dc.html` was redesigned around a calendar and categories,
and `NewCategory.dc.html` was added; the other artboards are unchanged. Both were re-copied into `design/`. The
design calls a check in a category a **task** in places ("Add task", "Add 3 tasks to Daily") and a **check** in
others ("Add checks", "3 checks planned"); the copy is ported as written, and the code keeps the name `Check`.

| Topic | Decision |
|---|---|
| **Category** | From `NewCategory.dc.html`: a category has a **name**, an **icon** (12: suitcase, sun, home, bin, lock, pill, flame, plug, car, key, heart, globe), a **colour** (the six tile colours), a **repeat** rule, its **tasks** (checks), and a **Remind me at** time ("Only if something’s not logged"). Every check belongs to exactly one category. Categories have an order (the filter chips and sections follow it). Icons map to SF Symbols (`suitcase.fill`, `sun.max.fill`, `house.fill`, `trash.fill`, `lock.fill`, `pills.fill`, `flame.fill`, `powerplug.fill`, `car.fill`, `key.fill`, `heart.fill`, `globe`). |
| **Repeat rules** | From the design: **Daily** ("Every day"), **Weekly** on a weekday ("Every Friday"), **Every 2 weeks** ("Every other Friday", counted from the week it was set), **Monthly** on a day ("Monthly on the 1st"), **Yearly** on a date ("Every year, Nov 6"), and **On a date**, once ("Once · Fri, Nov 6"). Proposed: a monthly day past the month's end (29–31) falls on its last day; Feb 29 yearly falls on Feb 28 in other years; due days use the **Day starts at** boundary and the current calendar, so DST and travel behave as for "today". |
| **Default category** | Proposed: there is always one default category, **Daily** (sun, Violet, Every day), created on a new install and by the migration. It can be renamed and re-iconed, but not deleted and not rescheduled, so "Move tasks to Daily" always has a target. |
| **Done** | From `Main.dc.html`: a task is **done on a day when it has a log in that day** (the Day starts at boundary). A category is **due** on a day when its repeat rule says so; only due categories show for that day. Proposed: a task can still be logged on a day it isn't due (from Siri, a widget, Detail or the Action Button); the log is kept and shown in History, but it counts only toward the day it falls on. |
| **Today: calendar** | From `Main.dc.html` (2026-10-30, the user: **7 days ahead, as drawn**): a strip of seven days starting today ("Today", then "Sat", "Sun"…, with the date), each with up to three dots in the colours of the **non-daily** categories due that day (white on the selected day). Selecting a day shows that day. Past days aren't in the strip; History covers them. The date line reads "Today · Fri, Oct 30" or "Sat, Oct 31". |
| **Today: filter** | From the design: chips **All** and one per category (its icon on its colour), then a dashed **New category** chip. A filter shows only that category's section. |
| **Today: progress bar** | From the design: a card that **sticks** below the top as the page scrolls. Scope line: "Today", "{Category} · today", or "All · Sat, Oct 31" / "{Category} · Sat, Oct 31". Main line: "{done} of {total} done" today, "{n} checks planned" (or "1 check planned") on a later day, "Nothing due" with none. Pill: "{n} left", **All clear** (the card turns Mint, with a check), "Free day" (none due), "Upcoming" (a later day). Under it, one segment per task, filled with the task's tile colour once done. It's announced as a status. |
| **Today: sections** | From the design: one section per due category, in category order: its icon on its colour, the name, the repeat label, and "{done}/{total}". Under it a **3-column grid** of square tiles and an **Add task** tile (dashed, the category's colour) that opens the Add sheet for that category. |
| **Today: tiles** | From the design: a square tile with the task's icon on a circle, its name (two lines at most) and one short line: the time when done ("8:42 AM", with a check badge on the icon), "Tap to log" today, "Upcoming" on a later day. Done tiles fill with the tile colour; undone tiles today are dashed outlines; tiles on a later day are plain white and **can't be logged**. The camera button (44 pt target, top right) shows only today, logs with a photo or retakes it, with the yellow photo dot once a photo exists. Proposed: the tile colour cycles Violet, Sun, Coral, Mint, Sky, Pink by the task's position in the **whole list** (category order, then task order), not by its place on screen as the design's script does, so a task keeps its colour across days, filters, widgets and Detail. |
| **Today: empty and upcoming** | From the design: with nothing due, a card **Nothing due** with "No checks scheduled for {date}." (or "{Category} isn’t due on {date}. Check Coming up below." when filtered). A dashed **Add checks** button under the sections. **Coming up**: the next three non-daily categories due within 31 days that aren't due on the selected day, each with its icon, "{n} checks · {repeat}", and "Tomorrow", a weekday (within a week) or "Nov 2"; tapping one within the strip selects that day. A store with no checks at all still shows the Phase 3 empty state. |
| **Today: tab bar** | From the design: the **Today** tab carries a progress ring of today's due tasks ("Today: 4 of 8 checked" to VoiceOver); History and **+** (Add checks) as before. The **Recent** list is gone from Today (History has it). |
| **Undo toast** | Unchanged: "Logged · {name}" / "Photo saved · {name}" with Undo for 5 s, the 10 s refresh rule, a haptic. |
| **Add sheet** | From the design: title "Add to {Category}", "Pick as many as you like.", an **Add to** row of category chips (the selected one filled with its colour), suggestion chips (Car locked, Tap off, Back door locked, Hair tool off, Lights off, Garage shut, Heater off, Keys packed, hiding names that exist in any category), "Something else?" with Add, and the button "Pick at least one" (disabled) / "Add 1 task to {Category}" / "Add {n} tasks to {Category}". It opens on the filtered category, the section's category (Add task), or Daily. A task's kind (its icon) still follows its name. |
| **New category** | From `NewCategory.dc.html`: a full-screen page with a close (×) button and "New category": a live **preview card** in the chosen colour (icon, name or "New category", the repeat summary, "{n} tasks · Reminder at 8:00 PM"); **Name** ("e.g. Travel, Gym, Leaving work"); **Icon** (a 6-column grid); **Colour** (six swatches); **Repeat** chips with "On" weekday buttons (Weekly, Every 2 weeks), "Day of the month" (Monthly), or a date ("Date each year" / "Date"); **Tasks** (each with a colour dot and a remove button, plus "Add a task, e.g. Passport packed" and +); **Remind me at**; and **Create category**. Proposed: Create is disabled until there's a name; a name already used (ignoring case) is refused; the reminder is off until a time is set (the design's 8 PM is the time it starts at when turned on); the date picker defaults to the next matching day. |
| **Manage categories** | Proposed (missing from the design): the same page as **Edit category** (Save instead of Create), opened from a filter chip's or a section header's context menu (Edit, Delete) and from **Categories** (2026-10-30, the user: a button beside Settings at the top right of Today, no longer in Settings), a list to edit and drag to reorder. A task moves to another category from its tile's context menu and from Detail (**Category**). |
| **Delete a category** | 2026-10-30, the user: **ask each time**: the confirmation offers "Delete category and its {n} tasks" (their logs and photos go too) or "Move {n} tasks to Daily". The default category can't be deleted. Proposed: a one-off ("On a date") category stays after its date: off Today, listed under **Past** in Categories until deleted. |
| **Category reminders** | 2026-10-30, the user: **category only**: one reminder per category at its time on each due day, only if a task in it isn't logged that day ("Bin night — 2 left: Bins out, Recycling out"). The per-check reminder goes (the Detail row too); the migration gives Daily the earliest existing per-check reminder time. The budget (60 of iOS's 64), the background refresh and removal once the category is done carry over. Proposed: **Log it** shows only when one task is left; with more, a tap opens Today filtered to that category. |
| **Other surfaces** | Proposed: **widgets** keep showing one check's latest log (the medium widget shows the first four tasks due today); **Siri**'s "Did I…?" answers "Not due today. Last done Friday, 7:05 AM" for a task not due; **Ask me which** lists today's due tasks first; the **leave-home nudge** counts only tasks due today; **History** gains a category filter. Detail, Logged, the Lock Screen and the Action Button page are unchanged in the design. |
| **Data model** | Proposed: `SchemaV2` adds `CheckCategory` (id, name, icon, colour, repeat kind, weekday, year, month, day, reminder minutes, order, isDefault, timestamps) and `Check.category`, and drops `Check.reminderMinutes`, with a **custom migration stage** from V1: create Daily, put every check in it, and move the earliest reminder time to Daily. Stores hand out `CategoryRecord`s, as they do `CheckRecord`s. 2026-10-30, while building: the model is `CheckCategory`, because `Category` clashes with the Objective-C runtime's type of that name; Daily has a fixed id, so the app, the widget extension and the migration agree on it; days in rules are stored as calendar dates (year, month, day), not `Date`s, so a time-zone change can't move them; the category colour is a `TileSwatch`. |

## Open questions

Ask each before the phase that needs it, then move the answer into Resolved decisions with the date.

1. **Phase 10 (built as proposed, 2026-10-30, the user asked to keep going)**: the leave-home nudge needs **Always**
   location permission, asked only after someone sets a home in Settings › Reminders. Keep it, or drop the nudge
   (and the Detail switch)?
2. **Phase 11 (built as drawn, 2026-10-30)**: the app icon is **Violet**; switch to another of the logo's colourways
   (Coral, Ink, Mint)? Re-render from `design/icon/*.svg` with `rsvg-convert`.

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
| Today redesign: day strip, filter chips, sticky progress bar, category sections, 3-column tiles, Coming up, ring tab | `Main.dc.html` (2026-10-30 update) | 14–15 |
| Add sheet with "Add to" categories | `Main.dc.html`, `AddChecks.dc.html` (2026-10-30 update) | 16 |
| New category and its schedule | `NewCategory.dc.html` | 16 |

---

## Phase 0 — Project foundation ✅ Done 2026-10-30, merged into main (launched on the simulator; unit and UI tests pass)

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

## Phase 1 — Checks, logs & rules ✅ Done 2026-10-30, merged into main (unit and UI tests pass)

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

## Phase 2 — Design system ✅ Done 2026-10-30, merged into main (gallery checked on the simulator in both themes; dark palette awaiting the user's sign-off, screenshots in `design/review/`)

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

## Phase 3 — Today ✅ Done 2026-10-30, merged into main (checked on the simulator, empty and with sample data; unit and UI tests pass)

Branch `feature/phase-3-today`.

- `TodayViewModel` over the stores and rules: tiles, the header and summary, Recent, the toast and undo.
- The Today screen as `Main.dc.html`: the date, title, chip and summary, the grid with tap-to-log and a haptic,
  the Add checks tile (opens a placeholder until Phase 4), Recent with "See all", and the floating bar.
- The empty state for a new install. Refetch when the app becomes active.

**Done when** view-model tests cover logging, undo and the summary with stubs, and a UI test logs a check and undoes
it.

## Phase 4 — Add & manage checks ✅ Done 2026-10-30, merged into main (checked on the simulator; unit and UI tests pass)

Branch `feature/phase-4-checks`.

- The Add checks sheet as drawn: chips, "Something else?", the commit button's copy; new checks go to the end.
- A tile's context menu and Detail's actions: rename, change icon, remove (with confirmation); drag to reorder.
- The TipKit tips (hold a tile to edit; the widget and Action Button tips are wired in Phases 8–9).

**Done when** UI tests add two suggestions and a custom check, and rename, reorder and remove one.

## Phase 5 — Photo proof ✅ Done 2026-10-30, merged into main (unit and UI tests pass; the camera itself needs a device)

Branch `feature/phase-5-photos`.

- A camera service behind a protocol (a `PhotosPicker` stand-in in the DEBUG Simulator), the photo store (HEIC
  plus thumbnail in the group container), and log-with-photo / retake from the tile's camera button.
- The photo badge, the full-screen viewer, Keep photos retention, the launch sweep, and the camera-denied state.

**Done when** store tests cover saving, retention and orphan sweeping, and logging with a photo works on a device.

## Phase 6 — Detail & History ✅ Done 2026-10-30, merged into main (checked on the simulator; unit and UI tests pass)

Branch `feature/phase-6-history`.

- Detail as `Detail.dc.html`: the header with the latest log and photo, the timeline with sources and the count,
  **Log it again**, and Remove. The nudge switch is shown and stored; it does nothing until Phase 10.
- The all-checks History grouped by day, with the check filter and swipe to delete.

**Done when** UI tests log from Detail and delete a log from History.

## Phase 7 — Settings ✅ Done 2026-10-30, merged into main (checked on the simulator; unit and UI tests pass)

Branch `feature/phase-7-settings`.

- The root Settings: Appearance, Day starts at, Action Button, Reminders (placeholder until Phase 10), Hide names on
  Lock Screen, Keep photos, Delete all logs and photos, About.
- The Action Button page as `ActionButton.dc.html`, with the setup help, hidden on devices without the button.

**Done when** each setting persists and takes effect, and a UI test changes the appearance and the day start.

## Phase 8 — App Intents, Siri & the Action Button ✅ Done 2026-10-30, merged into main (intents in the app's metadata; unit and UI tests pass; Siri and the button need a device)

Branch `feature/phase-8-intents`. In `Shared/`, so the widget can use them in Phase 9.

- `CheckEntity` (indexed for Spotlight) and its query; `LogCheckIntent`, `OpenCheckIntent`, `LastLogIntent`; the
  `AppShortcutsProvider` phrases.
- The Action Button flow from its settings: one check logs directly; "Ask me which" disambiguates; the interactive
  Logged snippet (Undo, Add a photo); Open camera; the in-app Logged screen.
- Check whether a background intent can play the strong haptic; if not, ask the user.

**Done when** unit tests call each intent's `perform()` against an in-memory store, and Siri and the Action Button
log on a device.

## Phase 9 — Widgets & the Control Center control ✅ Done 2026-10-30, merged into main (extension embeds and builds; widget previews in Xcode; unit and UI tests pass; placing widgets needs the Simulator's or a device's Home and Lock Screen)

Branch `feature/phase-9-widgets`.

- A widget extension target that joins `Shared/` and the App Group, with the app's Swift settings and the fonts.
- Lock Screen circular and rectangular widgets as `LockScreen.dc.html` (interactive, privacy-sensitive, Hide names
  respected); Home Screen small and medium; the Control Center control.
- Timeline reloads after a log and at day start; the Darwin notification and history read so the app sees widget
  writes.

**Done when** each widget renders in its families in both themes (previews), and a widget log appears in the open
app.

## Phase 10 — Reminders ✅ Done 2026-10-30, merged into main (unit and UI tests pass; notifications and leaving home need a device) — open question 1 not yet answered, built as proposed

Branch `feature/phase-10-reminders`. Ask open question 1 first.

- Notification permission; per-check time reminders within the 64-notification budget, rescheduled on log, launch
  and background refresh; the **Log it** action.
- The leave-home nudge: home location in Settings, the `CLMonitor` recreated at launch, the nudge and the optional
  reassurance; the location usage strings; the denied states.

**Done when** scheduler tests cover the budget and removal on log (with a stub notification center), and a reminder
and a nudge fire on a device.

## Phase 11 — App icon & name ✅ Done 2026-10-30, merged into main (Violet, as drawn; open question 2 not yet answered)

Branch `feature/phase-11-icon`. Ask open question 2 first.

- The logo rendered from `Logo.dc.html` to `design/icon/DidIAppIcon{,-Dark,-Tinted}.svg`, then 1024 px PNGs
  (`rsvg-convert`, alpha removed) in the app icon set: default (Violet), dark (Ink with a cream stroke), tinted
  (white glyph on black). The widgets use SF Symbols, so no separate glyph asset was needed. A single-size icon
  can't drop the check at 44 px; iOS scales the 1024 art.

**Done when** the icon shows on the Home Screen in light, dark and tinted modes.

## Phase 12 — iPad, accessibility & polish ✅ Done 2026-10-30, merged into main (iPad split view and an accessibility size checked on the simulator; unit and UI tests pass; usage strings await the user's review)

Branch `feature/phase-12-polish`.

- `NavigationSplitView` on regular width (Today beside Detail), landscape on every size class, form sheets on iPad.
- Dynamic Type up to the accessibility sizes (the grid reflows to one column), VoiceOver copy from the design's
  `aria-label`s, Reduce Motion and Reduce Transparency, contrast in both themes, a localization pass.
- Review the usage strings and the privacy manifest with the user.

**Done when** a layout UI test passes on an iPad and at an accessibility text size, and the full suite is green.

---

The phases below follow the canvas update (see **Categories & calendar**). Each starts from an up-to-date `main`.

## Phase 13 — Categories & schedules (core) ✅ Done 2026-10-30, merged into main (builds; migration checked on the simulator's real V1 store; tests not yet run)

Branch `feature/phase-13-categories-core`. Pure code and stores in `Shared/`, no UI.

- `SchemaV2`: the `CheckCategory` model and `Check.category`, without `Check.reminderMinutes`; a custom migration
  stage from V1 that creates Daily, moves every check into it, and gives it the earliest per-check reminder time.
  `SchemaV1` keeps frozen copies of the V1 models; the app's `Check`, `LogEntry` and `CheckCategory` are
  `SchemaV2`'s.
- `CategoryIcon` (the 12 icons and their SF Symbols), `TileSwatch` as the category colour, and `RepeatRule`
  (the six kinds, `isDue(on:)`, the next due day, and its labels: "Every Friday", "Monthly on the 1st", "Once · Fri,
  Nov 6").
- `CategoryStoring` and its SwiftData implementation: add (with tasks), edit, reorder, delete with its tasks or
  moving them to Daily, and move a task to another category. Daily always exists and can't be deleted.
- `DayAgenda`: for a day and a filter, the due categories and their tasks, done states, the progress bar's copy
  and segments, the strip's dots, Coming up, and the Today ring; the tile colour by position in the whole list.
- Update the callers that read `reminderMinutes` so everything builds; Phase 17 rebuilds reminders on categories.
  Until then each check reminds at its category's time on the category's due days, and Detail's reminder row sets
  the category's time. Today stays the flat list until Phase 15, which also seeds the design's four categories
  for `-SeedSample`.

**Done when** table tests cover every repeat rule (including the 31st in short months, Feb 29, every other week
from its anchor, a day start after midnight and DST changes), the progress copy and Coming up; store tests cover
delete-with-tasks and move-to-Daily; and a V1 store file on disk migrates to V2 with its checks, logs and reminder.

## Phase 14 — Calendar & category components ✅ Done 2026-10-30, merged into main (the user said to continue; gallery checked in both themes and at an accessibility size; tests not yet run)

Branch `feature/phase-14-calendar-components`.

- Components from `Main.dc.html`: the day strip cell (with dots), the category filter chip (with its icon on its
  colour) and the dashed New category chip, the progress bar card (scope, main line, pill, segments, the Mint "All
  clear" state), the section header, the 3-column square tile (done, undone, upcoming; check badge; camera button
  with the photo dot), the Add task tile, the Coming up row, the Today tab's progress ring.
- From `NewCategory.dc.html`: the preview card, the icon grid, the colour swatches, the repeat chips, the weekday
  buttons, the task row.
- Dark appearances for each, and the DEBUG gallery updated (both themes, default and accessibility sizes).

**Done when** the gallery shows every new component in both themes, and the user has approved the screenshots in
`design/review/`.

Built: `DayStripCell`, `CategoryChip` (filter and Add to) and `NewCategoryChip`, `ProgressBarCard`,
`CategorySectionHeader`, `TaskTile` and `AddTaskTile`, `ComingUpRow`, `NothingDueCard`, `AddChecksButton`,
`ProgressRing` (in `FloatingTabBar`), `CategoryBadge`, and `CategoryPreviewCard`, `CategoryIconGrid`,
`ColourSwatchPicker`, `WeekdayPicker`, `CategoryTaskRow`. The gallery opens on them with `-GalleryCalendar`,
`-GalleryAgenda` and `-GalleryCategory`; screenshots are `design/review/gallery-{calendar,agenda,category}-*.png`.
Proposed, taken without asking: in dark, the selected day and Today's "{n} left" pill are Sun with ink text (a new
`selection` colour set, ink in light), because the ink-on-ink of the light design disappears on the dark surface.
Left for Phase 18, as planned: at accessibility sizes the 3-column grid truncates names and the strip's weekdays
shorten ("M…"). Like the design, a Mint task's segment doesn't show on the Mint "All clear" card.

## Phase 15 — Today as a calendar ✅ Done 2026-10-30, merged into main (checked on the simulator, today and a later day; tests not yet run)

Branch `feature/phase-15-today-calendar`.

- `TodayViewModel` over `DayAgenda`: the selected day, the filter, sections, the sticky progress bar, Nothing due,
  Coming up, the ring, logging (today only) with the toast and undo; the selected day returns to today at the day
  change and when the app comes back after a day change.
- The screen as `Main.dc.html`: date line and title, strip, filter chips, the pinned progress bar
  (`LazyVStack(pinnedViews:)`), the sections with their grids and Add task tiles, the Add checks button, Coming up,
  and the tab bar's ring. The Recent list goes; the empty install keeps the Phase 3 empty state.
- The split view on iPad keeps Today beside a task's Detail.

**Done when** view-model tests cover the selected day, filters, done counts and logging only today (with stubs),
and UI tests log and undo a task, switch to a later day (tiles read "Upcoming" and don't log) and filter by a
category.

Built as planned. Also: the grid's reflow (3 columns, 2 at the first two accessibility sizes, 1 beyond) came
forward from Phase 18 so the accessibility layout test keeps passing; the Add task tile and the Add checks button
open the sheet on that category (the sheet adds there; its "Add to" chips come in Phase 16); a tile can be
dragged only within its category; `-SeedSample` seeds the design's four categories, with Bin night due today. The
old 2-column `CheckTile`, `AddTile`, `ProgressPill` and the `TodaySummary` rule were removed.

## Phase 16 — Category management & the Add sheet ✅ Done 2026-10-30, merged into main (New category and Settings › Categories checked on the simulator; tests not yet run)

Branch `feature/phase-16-category-management`.

- New category as `NewCategory.dc.html`, and the same page as Edit category; validation (a name, no duplicates).
- Entry points: the New category chip, a filter chip's and a section header's context menu (Edit, Delete), and
  Settings › Categories (edit, drag to reorder, Past one-off categories).
- Delete with the choice of deleting the tasks or moving them to Daily; move a task between categories from its
  tile and from Detail (a **Category** row).
- The Add sheet's **Add to** chips and new copy, opened for the right category; the suggestion list as drawn.
- TipKit: a tip on the New category chip once there are three or more tasks.

**Done when** view-model tests cover create, edit, validation and both delete choices, and UI tests create a weekly
category with two tasks (it shows on its day in the strip), add tasks to it from its section, move a task to
another category, and delete a category both ways.

Built as planned. Proposed, taken without asking: Edit category lists a category's existing tasks without remove
buttons (removing a task stays on its tile's menu, with the confirmation) and adds new ones on Save; a new
category starts on today's weekday and day of the month, tomorrow's date and the first colour no category uses;
a name already used shows "There’s already a category called “…”." under the form; Settings › Categories rows
read "Every Friday · 2 tasks", reorder by holding and dragging and delete by swiping; a task moves from its tile's
**Move to** menu and Detail's **Category** row; the Add sheet keeps the design's four Daily checks ahead of its
eight suggestions until each exists.

## Phase 17 — Reminders, intents & widgets follow categories ✅ Done 2026-10-30, merged into main (builds; tests not yet run; a category reminder firing still needs a device)

Branch `feature/phase-17-category-reminders`.

- Category reminders on due days, within the 60-request budget, removed once the category is done that day; the
  copy with the tasks left; **Log it** only with one task left, else the tap opens Today on that category. The
  check page's reminder row goes; Settings › Reminders lists categories with their times.
- The leave-home nudge counts only tasks due today; Siri's "Did I…?" answers for tasks not due today; Ask me which
  lists today's due tasks first; Spotlight indexes categories' tasks as before; the medium widget shows the first
  four tasks due today; History gains a category filter.
- Widget timelines also reload when categories change.

**Done when** scheduler tests cover category reminders (due days only, the budget, removal), intent tests cover
the new answers, and a category reminder fires on a device.

Built as planned: a reminder's title is the category and its body "2 left: Bins out, Recycling out"; with one
task left it carries **Log it**, otherwise a tap opens Today on that category (a separate notification category
without the action); a category with no tasks doesn't remind. Siri answers "Not due today. Last done …" or
"{task} isn’t due today." (a log today still answers "Yes."). The overview widget's next-day entry recomputes
which tasks are due. History shows category chips above the check chips once there's more than Daily. Turning a
category's reminder on asks for notification permission. Settings › Reminders lists category reminders and the
nudged checks in two groups.

## Phase 18 — Polish for the redesign ✅ Done 2026-10-30, merged into main (checked on the simulator: both themes, an accessibility size and the iPad split view; tests not yet run)

Branch `feature/phase-18-calendar-polish`.

- Dynamic Type: the tile grid goes from 3 columns to 2 and then 1 at accessibility sizes; the strip scrolls
  sideways at large sizes; the progress bar wraps. VoiceOver copy from the design's `aria-label`s ("Sat, Oct 31,
  2 extra categories due", "Add a task to Bin night", "Stove off, not logged — tap to log").
- Reduce Motion for the sticky bar's shadow and the ring; contrast of the category colours in both themes (dark
  text on Sun, Coral, Mint, Sky and Pink as drawn).
- iPad: the strip and sections use the wider column (more tiles per row); landscape.
- Strings in `Localizable.xcstrings`, plurals for task and check counts; screenshots of the new screens in
  `design/review/`.

**Done when** layout UI tests pass at an accessibility text size and on an iPad, and the full suite is green.

Built: the strip scrolls sideways at accessibility sizes (104 pt days); the grid adds a column per ~130 pt on wide
columns (landscape), keeping three on phones; the tab bar's labels stay on one line beside the ring. The string
catalog was empty (Xcode fills it only when building in the IDE), so it was synced from a Release build's
extracted strings with `xcstringstool sync` (338 strings, no DEBUG ones), with English plural variants for the
task, check, log and "left" counts. Screenshots: `design/review/today-{light,dark,ax}.png`,
`new-category-{light,dark}.png`, `ipad-split.png`.

## Follow-ups (2026-10-30, the user)

Branch `feature/today-tab-and-categories-button`.

- **The Today tab goes back to today.** Tapping **Today** in the floating bar, even while Today is showing,
  selects today, clears the category filter and scrolls back to the top.
- **Categories sits beside Settings.** A round Categories button (`square.grid.2x2.fill`) at the top right of
  Today opens the categories list (edit, reorder, delete, Past). It's gone from Settings, and the screen is now
  `CategoriesView` with "Today" as its back title.
- **Tips go away on their own.** "Hold a tile to change it" and "Group your checks" hide about 5 seconds after
  they first show, for good (`autoDismissing(_:after:)` in `DidITips.swift`). Proposed, taken without asking: not
  while VoiceOver is running, so a tip can't vanish before it's read.

Found while testing these (fixed on the same branch):
- **Add task opened the sheet on Daily.** The sheet was `.sheet(isPresented:)` reading a category set in the same
  tap; it's now `.sheet(item:)` with an `AddChecksRequest` that carries the category.
- **Create category covered the field being typed.** While a field has focus, the floating Create button hides
  and a **Done** button sits above the keyboard (it also adds a task still being typed); return in the task field
  keeps you typing tasks.
- **Test fixes.** The full run on 2026-10-30 went 169 passed, 4 failed, 1 skipped. The failures were a spliced
  nudge test, a timing-sensitive toast test, and two category UI tests that tapped under the tab bar or the
  keyboard. Those tests have been fixed and pass when rerun on their own.

## Phase 19 — Compact Today ✅ Done 2026-10-30, merged into main (checked on the simulator: grid and list, both themes, an accessibility size, the iPad split; tests not yet run)

Branch `feature/phase-19-compact-today`. The canvas changed again on 2026-10-30: only `Main.dc.html`, now a compact
Today; the other artboards are unchanged (re-copied into `design/`). The user, 2026-10-30: **Today only**, and the
header keeps **the view toggle, Categories and Settings**. Where this differs from **Categories & calendar**
above (the Today rows), this wins.

| Topic | Decision |
|---|---|
| **Header** | From the design: "Today" (or the weekday, "Sat") with "Fri, Oct 30" (or "Oct 31") on one line; the "Did I?" title goes. Then the grid/list toggle, Categories (`rectangle.stack.fill`, so it isn't mistaken for the grid icon) and Settings. |
| **Strip** | From the design: 54 pt days, one letter per weekday ("Today" stays), 17 pt dates, 5 pt dots. VoiceOver reads "Sat, Oct 31, also due: Bin night, Home safety". |
| **Sticky block** | From the design: the progress bar is one line (scope, "4 of 6 done", the pill) over its segments, and the filter chips pin with it. Scope is the filter's name, else "Today", else the weekday; a later day reads "{n} tasks planned"; nothing due reads "Free". Chips have no border (a faint ink fill); New category is a dashed + circle. Proposed: not pinned at accessibility sizes, where it would cover much of the screen. |
| **Sections** | From the design: the header opens or closes the section (meta line "Every Friday" or "All done · last 8:42 AM", a mint "✓ 2/2" once all done, a chevron), and a + adds tasks (the Add task tile goes). A section starts closed once all its tasks are done today. Tasks not done come first. Proposed: a section opened or closed by hand stays so until the day changes; adding from its + opens it. |
| **Grid or list** | From the design: a toggle between 3-column tiles (tighter: radius 20, 30 pt icons, 28 pt camera) and 52 pt rows. Proposed: the choice is kept in settings (`AppSettings.todayLayout`); at accessibility sizes Today always uses rows (square tiles in one column would be huge), and a row puts its status under the name. |
| **Removed** | From the design: the dashed "Add checks" button (the tab bar's + stays, now "Add tasks") and **Coming up** (the strip's dots show what's due). "Nothing due" reads "{Category} isn’t due on {date}. The dots on the days above show when it is." or "No tasks scheduled for {date}." |
