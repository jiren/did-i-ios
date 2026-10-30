#if DEBUG
import SwiftUI

/// Every design-system component, for checking both themes and text sizes. Launch with `-Gallery` (or
/// `-GalleryControls`, `-GalleryCalendar`, `-GalleryAgenda`, `-GalleryCategory` to start at those).
struct ComponentGallery: View {
    var page: GalleryPage = .tiles
    @State private var chipOn = true
    @State private var switchOn = true
    @State private var tab: MainTab = .today
    @State private var icon: CategoryIcon = .suitcase
    @State private var colour: TileSwatch = .sky
    @State private var weekday = 6

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch page {
                case .tiles: calendarSection; controlsSection
                case .controls: controlsSection
                case .calendar: calendarSection
                case .agenda: agendaSection
                case .category: categorySection
                }
            }
            .padding(20)
        }
        .background(Color.ground)
    }

    @ViewBuilder
    private var controlsSection: some View {
                SectionLabel(title: "A press logs")
                FlowLayout(spacing: 8) {
                    ChoiceChip(title: "Windows closed", isOn: chipOn) { chipOn.toggle() }
                    ChoiceChip(title: "Car locked", isOn: !chipOn) { chipOn.toggle() }
                }
                SwitchRow(title: "Nudge me when I leave home", subtitle: "Only if it isn’t logged yet",
                          symbolName: "bell.fill", isOn: $switchOn)
                HStack {
                    RoundIconButton(systemName: "gearshape.fill", label: "Settings") {}
                    RoundIconButton(systemName: "xmark", label: "Close", style: .sand) {}
                    RoundIconButton(systemName: "chevron.left", label: "Back", style: .onColor) {}
                        .padding(6).background(Color.tileViolet, in: .capsule)
                }
                VStack(spacing: 0) {
                    TimelineRow(title: "Today, 8:42 AM", subtitle: "Action Button · photo", isNewest: true, isLast: false)
                    TimelineRow(title: "Yesterday, 10:58 PM", subtitle: "Lock Screen widget", isNewest: false, isLast: true)
                }
                Button("Log it again") {}.buttonStyle(PillButtonStyle())
                Button("Add 2 checks") {}.buttonStyle(PillButtonStyle(variant: .brand))
                Button("Pick at least one") {}.buttonStyle(PillButtonStyle(variant: .brand)).disabled(true)
                UndoToast(message: "Logged · Front door locked") {}
                FloatingTabBar(selection: $tab) {}
    }

    // MARK: - Calendar (phase 14, compact in phase 19)

    @ViewBuilder
    private var calendarSection: some View {
        let today = GallerySample.agenda()
        let saturday = GallerySample.agenda(day: CalendarDay(year: 2026, month: 10, day: 31))
        TodayHeader(dayTitle: today.dayTitle, daySub: today.daySub, layout: .grid, onToggleLayout: {}, onCategories: {}, onSettings: {})
            .padding(.horizontal, -20)
        HStack(spacing: 6) {
            ForEach(today.strip) { day in DayStripCell(day: day) {} }
        }
        ProgressBarCard(progress: today.progress, isToday: true, isStuck: true)
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                CategoryChip(title: "All", isSelected: true) {}
                ForEach(GallerySample.categories) { category in
                    CategoryChip(title: category.name, icon: category.icon, colour: category.colour, isSelected: false) {}
                }
                NewCategoryChip {}
            }
        }
        .scrollIndicators(.hidden)
        ProgressBarCard(progress: GallerySample.agenda(allClear: true).progress, isToday: true)
        ProgressBarCard(progress: saturday.progress, isToday: false)
        if let section = today.sections.first { sectionView(section, layout: .grid) }
    }

    @ViewBuilder
    private var agendaSection: some View {
        let today = GallerySample.agenda()
        let saturday = GallerySample.agenda(day: CalendarDay(year: 2026, month: 10, day: 31))
        if let daily = today.sections.first { sectionView(daily, layout: .list) }
        ForEach(today.sections.dropFirst()) { section in sectionView(section, layout: .grid) }
        if let allDone = GallerySample.agenda(allClear: true).sections.last {
            sectionView(allDone, layout: .grid, isExpanded: false)
        }
        Text("Sat, Oct 31").font(.didLabel).foregroundStyle(Color.muted)
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(saturday.sections[0].tasks.prefix(2)) { task in
                TaskTile(content: GallerySample.content(task, isToday: false), onLog: {}, onPhoto: {})
            }
        }
        TaskRow(content: GallerySample.content(saturday.sections[0].tasks[0], isToday: false), onLog: {}, onPhoto: {})
        NothingDueCard(text: "Travel isn’t due on Fri, Oct 30. The dots on the days above show when it is.")
        FloatingTabBar(selection: $tab, todayProgress: 4 / 6, todayAccessibilityLabel: today.ringAccessibilityLabel) {}
    }

    @ViewBuilder
    private func sectionView(_ section: DayAgenda.Section, layout: TodayLayout, isExpanded: Bool = true) -> some View {
        CategorySectionHeader(
            category: section.category,
            meta: section.isAllDone ? "All done · last 10:27 AM" : section.repeatLabel,
            progressText: section.isAllDone ? "✓ \(section.progressText)" : section.progressText,
            isAllDone: section.isAllDone, isExpanded: isExpanded, onToggle: {}, onAdd: {}
        )
        if isExpanded {
            switch layout {
            case .grid:
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(section.tasks) { task in
                        TaskTile(content: GallerySample.content(task, isToday: true), onLog: {}, onPhoto: {})
                    }
                }
            case .list:
                VStack(spacing: 6) {
                    ForEach(section.tasks) { task in
                        TaskRow(content: GallerySample.content(task, isToday: true), onLog: {}, onPhoto: {})
                    }
                }
            }
        }
    }

    // MARK: - New category (phase 14)

    @ViewBuilder
    private var categorySection: some View {
        CategoryPreviewCard(
            name: "Weekend trip", icon: icon, colour: colour, repeatSummary: "Once · Fri, Nov 6",
            detail: "3 tasks · Reminder at 8:00 PM"
        )
        SectionLabel(title: "Icon")
        CategoryIconGrid(selection: $icon, colour: colour)
        SectionLabel(title: "Colour")
        ColourSwatchPicker(selection: $colour)
        SectionLabel(title: "Repeat")
        FlowLayout(spacing: 8) {
            ForEach(RepeatKind.allCases, id: \.self) { kind in
                ChoiceChip(title: kind.title, isOn: kind == .weekly) {}
            }
        }
        WeekdayPicker(selection: $weekday, colour: colour)
        SectionLabel(title: "Tasks")
        ForEach(["Passport packed", "Charger packed", "Windows closed"], id: \.self) { name in
            CategoryTaskRow(name: name, colour: colour) {}
        }
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(GallerySample.categories) { category in
                    CategoryChip(
                        title: category.name, icon: category.icon, colour: category.colour,
                        isSelected: category.isDefault, style: .addTo
                    ) {}
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

/// `Main.dc.html`'s sample on Friday, Oct 30, 2026 at 10:42 AM.
private enum GallerySample {
    static let calendar = Calendar.autoupdatingCurrent
    static let categories: [CategoryRecord] = [
        CategoryRecord(id: CategoryDefaults.dailyID, name: "Daily", icon: .sun, colour: .violet, rule: .daily, order: 0, isDefault: true),
        CategoryRecord(id: UUID(), name: "Bin night", icon: .bin, colour: .mint, rule: .weekly(weekday: 6), order: 1, isDefault: false),
        CategoryRecord(id: UUID(), name: "Home safety", icon: .home, colour: .coral, rule: .monthly(day: 1), order: 2, isDefault: false),
        CategoryRecord(
            id: UUID(), name: "Travel", icon: .suitcase, colour: .sky,
            rule: .once(CalendarDay(year: 2026, month: 11, day: 2)), order: 3, isDefault: false
        ),
    ]
    static let checks: [CheckRecord] = [
        ("Front door locked", CheckKind.door, 0), ("Pill taken", .pill, 0), ("Stove off", .stove, 0), ("Iron unplugged", .plug, 0),
        ("Bins out", .other, 1), ("Recycling out", .other, 1), ("Smoke alarm tested", .stove, 2), ("Extinguisher checked", .other, 2),
        ("Passport packed", .other, 3), ("Charger packed", .plug, 3), ("Windows closed", .window, 3), ("Water main off", .tap, 3),
    ].enumerated().map { index, entry in
        CheckRecord(id: UUID(), name: entry.0, kind: entry.1, order: index, categoryID: categories[entry.2].id, nudgesOnLeavingHome: false)
    }
    static let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 30, hour: 10, minute: 42)) ?? Date()

    static func agenda(day: CalendarDay? = nil, allClear: Bool = false) -> DayAgenda {
        let logged = allClear ? [0, 1, 2, 3, 4, 5] : [0, 1, 2, 4]
        let logs = logged.map { index in
            LogRecord(
                id: UUID(), checkID: checks[index].id, date: now.addingTimeInterval(Double(-index - 1) * 900),
                source: .app, photoFileName: index == 0 ? "door.heic" : nil
            )
        }
        return DayAgenda(
            day: day, filter: nil, categories: categories, checks: checks, logs: logs, now: now,
            boundary: DayBoundary(calendar: calendar), locale: .autoupdatingCurrent
        )
    }

    static func content(_ tile: DayAgenda.Tile, isToday: Bool) -> TaskTileContent {
        let state: TaskTileContent.State = if let log = tile.log {
            .done(time: log.date.formatted(date: .omitted, time: .shortened))
        } else {
            isToday ? .toLog : .upcoming
        }
        return TaskTileContent(
            name: tile.check.name, kind: tile.check.kind, swatch: tile.swatch, state: state,
            hasPhoto: tile.log?.hasPhoto == true, accessibilityLabel: tile.check.name, photoButtonLabel: "Photo"
        )
    }
}

#Preview("Light") { ComponentGallery().preferredColorScheme(.light) }
#Preview("Calendar") { ComponentGallery(page: .calendar) }
#Preview("Category") { ComponentGallery(page: .category).preferredColorScheme(.dark) }
#Preview("Dark") { ComponentGallery().preferredColorScheme(.dark) }
#Preview("AX") { ComponentGallery().dynamicTypeSize(.accessibility2) }
#endif
