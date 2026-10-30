import Foundation

/// What Today shows for one day and filter (`Main.dc.html`'s `renderVals`): the 7-day strip, the due categories
/// with their tasks, the progress bar, Coming up and the Today tab's ring.
nonisolated struct DayAgenda: Equatable, Sendable {
    static let stripLength = 7
    static let maximumDots = 3
    static let comingUpLimit = 3
    static let comingUpHorizon = 31

    /// A task on a day, as a tile.
    struct Tile: Identifiable, Equatable, Sendable {
        var check: CheckRecord
        /// From the task's position in the whole list, so it keeps its colour across days and filters.
        var swatch: TileSwatch
        /// The newest log in the day, if any.
        var log: LogRecord?

        var id: UUID { check.id }
        var isDone: Bool { log != nil }
    }

    struct Section: Identifiable, Equatable, Sendable {
        var category: CategoryRecord
        var repeatLabel: String
        var tasks: [Tile]

        var id: UUID { category.id }
        var doneCount: Int { tasks.filter(\.isDone).count }
        /// "2/4".
        var progressText: String { "\(doneCount)/\(tasks.count)" }
    }

    struct StripDay: Identifiable, Equatable, Sendable {
        var day: CalendarDay
        /// "Today", then "Sat", "Sun"…
        var weekdayText: String
        var dayNumber: Int
        /// The colours of up to three non-daily categories due that day.
        var dots: [TileSwatch]
        var isToday: Bool
        var isSelected: Bool
        /// "Sat, Oct 31, 2 extra categories due".
        var accessibilityLabel: String

        var id: CalendarDay { day }
    }

    /// The progress bar's pill.
    enum Pill: Equatable, Sendable {
        case left(Int), allClear, freeDay, upcoming

        var text: String {
            switch self {
            case .left(let count): String(localized: "\(count) left")
            case .allClear: String(localized: "All clear")
            case .freeDay: String(localized: "Free day")
            case .upcoming: String(localized: "Upcoming")
            }
        }
    }

    struct Progress: Equatable, Sendable {
        /// "Today", "Bin night · today", "All · Sat, Oct 31", "Bin night · Sat, Oct 31".
        var scope: String
        /// "2 of 6 done", "4 checks planned", "Nothing due".
        var main: String
        var pill: Pill
        /// One per task in the bar's order; a done one fills with its tile colour.
        var segments: [Tile]

        var isAllClear: Bool { pill == .allClear }
    }

    struct Upcoming: Identifiable, Equatable, Sendable {
        var category: CategoryRecord
        var day: CalendarDay
        /// "2 checks · Every Friday".
        var detail: String
        /// "Tomorrow", "Sun" within a week, else "Nov 2".
        var when: String
        /// Within the strip, so tapping it can select the day.
        var isInStrip: Bool

        var id: UUID { category.id }
    }

    let today: CalendarDay
    let selectedDay: CalendarDay
    /// The category shown alone, or nil for All.
    let filter: CategoryRecord?
    /// "Today · Fri, Oct 30" or "Sat, Oct 31".
    let dateLine: String
    let strip: [StripDay]
    let sections: [Section]
    let progress: Progress
    /// "No checks scheduled for Sat, Oct 31." when no section is due, else nil.
    let nothingDueText: String?
    let comingUp: [Upcoming]
    /// Today's due tasks, whatever the selected day and filter, for the Today tab's ring.
    let todayDoneCount: Int
    let todayTotal: Int

    /// Only today's tasks can be logged.
    var isToday: Bool { selectedDay == today }

    /// "Today: 4 of 8 checked".
    var ringAccessibilityLabel: String {
        String(localized: "Today: \(todayDoneCount) of \(todayTotal) checked")
    }

    /// - Parameters:
    ///   - checks: every check, in the store's order.
    ///   - logs: the logs from at least today and the selected day (others are ignored).
    ///   - day: the selected day; nil, or a day before today, means today.
    init(
        day: CalendarDay?,
        filter filterID: UUID?,
        categories: [CategoryRecord],
        checks: [CheckRecord],
        logs: [LogRecord],
        now: Date,
        boundary: DayBoundary,
        locale: Locale
    ) {
        let calendar = boundary.calendar
        let today = boundary.calendarDay(containing: now)
        let selected = max(day ?? today, today)
        let categories = categories.sorted { ($0.order, $0.name) < ($1.order, $1.name) }
        let filter = categories.first { $0.id == filterID }
        let tasksByCategory = Self.tasksByCategory(categories: categories, checks: checks)

        self.today = today
        self.selectedDay = selected
        self.filter = filter

        let selectedDate = RepeatRule.shortDate(selected, calendar: calendar, locale: locale)
        dateLine = selected == today ? String(localized: "Today · \(selectedDate)") : selectedDate

        strip = (0..<Self.stripLength).map { offset in
            let stripDay = today.adding(days: offset, calendar: calendar)
            let dots = categories
                .filter { $0.rule != .daily && $0.rule.isDue(on: stripDay, calendar: calendar) }
                .prefix(Self.maximumDots)
                .map(\.colour)
            let name = RepeatRule.shortDate(stripDay, calendar: calendar, locale: locale)
            return StripDay(
                day: stripDay,
                weekdayText: offset == 0
                    ? String(localized: "Today")
                    : stripDay.noon(in: calendar).formatted(Self.style(calendar: calendar, locale: locale).weekday(.abbreviated)),
                dayNumber: stripDay.day,
                dots: Array(dots),
                isToday: offset == 0,
                isSelected: stripDay == selected,
                accessibilityLabel: dots.isEmpty ? name : String(localized: "\(name), \(dots.count) extra categories due")
            )
        }

        let selectedLogs = Self.newestLogs(in: boundary.interval(of: selected), logs: logs)
        sections = categories
            .filter { (filter == nil || $0.id == filter?.id) && $0.rule.isDue(on: selected, calendar: calendar) }
            .compactMap { category in
                let tasks = (tasksByCategory[category.id] ?? []).map { task in
                    Tile(check: task.check, swatch: task.swatch, log: selectedLogs[task.check.id])
                }
                return Section(category: category, repeatLabel: category.rule.label(calendar: calendar, locale: locale), tasks: tasks)
            }

        let segments = sections.flatMap(\.tasks)
        let doneCount = segments.filter(\.isDone).count
        let total = segments.count
        let isToday = selected == today
        let scopeName = filter?.name ?? (isToday ? String(localized: "Today") : String(localized: "All"))
        let pill: Pill
        let main: String
        if total == 0 {
            pill = .freeDay
            main = String(localized: "Nothing due")
        } else if isToday {
            pill = doneCount == total ? .allClear : .left(total - doneCount)
            main = String(localized: "\(doneCount) of \(total) done")
        } else {
            pill = .upcoming
            main = total == 1 ? String(localized: "1 check planned") : String(localized: "\(total) checks planned")
        }
        progress = Progress(
            scope: isToday
                ? (filter == nil ? scopeName : String(localized: "\(scopeName) · today"))
                : String(localized: "\(scopeName) · \(selectedDate)"),
            main: main,
            pill: pill,
            segments: segments
        )

        if sections.isEmpty {
            nothingDueText = filter.map { String(localized: "\($0.name) isn’t due on \(selectedDate). Check Coming up below.") }
                ?? String(localized: "No checks scheduled for \(selectedDate).")
        } else {
            nothingDueText = nil
        }

        comingUp = Self.comingUp(
            categories: categories, tasksByCategory: tasksByCategory, today: today, selected: selected,
            calendar: calendar, locale: locale
        )

        let todayLogs = selected == today ? selectedLogs : Self.newestLogs(in: boundary.interval(of: today), logs: logs)
        let todayTasks = categories
            .filter { $0.rule.isDue(on: today, calendar: calendar) }
            .flatMap { tasksByCategory[$0.id] ?? [] }
        todayTotal = todayTasks.count
        todayDoneCount = todayTasks.filter { todayLogs[$0.check.id] != nil }.count
    }

    /// The tasks of each category with their colours: the whole list is category order, then task order.
    private static func tasksByCategory(categories: [CategoryRecord], checks: [CheckRecord]) -> [UUID: [Tile]] {
        let known = Set(categories.map(\.id))
        let fallback = categories.first(where: \.isDefault)?.id ?? categories.first?.id
        var grouped: [UUID: [CheckRecord]] = [:]
        for check in checks.sorted(by: { $0.order < $1.order }) {
            guard let categoryID = known.contains(check.categoryID) ? check.categoryID : fallback else { continue }
            grouped[categoryID, default: []].append(check)
        }
        var position = 0
        var tasks: [UUID: [Tile]] = [:]
        for category in categories {
            tasks[category.id] = (grouped[category.id] ?? []).map { check in
                defer { position += 1 }
                return Tile(check: check, swatch: .at(position: position), log: nil)
            }
        }
        return tasks
    }

    private static func newestLogs(in interval: DateInterval, logs: [LogRecord]) -> [UUID: LogRecord] {
        var newest: [UUID: LogRecord] = [:]
        for log in logs where log.date >= interval.start && log.date < interval.end {
            if let current = newest[log.checkID], current.date >= log.date { continue }
            newest[log.checkID] = log
        }
        return newest
    }

    /// The next non-daily categories due within 31 days and not on the selected day, nearest first.
    private static func comingUp(
        categories: [CategoryRecord], tasksByCategory: [UUID: [Tile]], today: CalendarDay, selected: CalendarDay,
        calendar: Calendar, locale: Locale
    ) -> [Upcoming] {
        var upcoming: [Upcoming] = []
        var seen: Set<UUID> = []
        for offset in 1...comingUpHorizon where upcoming.count < comingUpLimit {
            let day = today.adding(days: offset, calendar: calendar)
            guard day != selected else { continue }
            for category in categories where upcoming.count < comingUpLimit {
                guard category.rule != .daily, !seen.contains(category.id),
                      category.rule.isDue(on: day, calendar: calendar),
                      !category.rule.isDue(on: selected, calendar: calendar) else { continue }
                seen.insert(category.id)
                let count = tasksByCategory[category.id]?.count ?? 0
                let label = category.rule.label(calendar: calendar, locale: locale)
                let date = day.noon(in: calendar)
                let when: String = switch offset {
                case 1: String(localized: "Tomorrow")
                case ..<stripLength: date.formatted(style(calendar: calendar, locale: locale).weekday(.abbreviated))
                default: date.formatted(RepeatRule.monthDay(calendar: calendar, locale: locale))
                }
                upcoming.append(Upcoming(
                    category: category,
                    day: day,
                    detail: count == 1 ? String(localized: "1 check · \(label)") : String(localized: "\(count) checks · \(label)"),
                    when: when,
                    isInStrip: offset < stripLength
                ))
            }
        }
        return upcoming
    }

    private static func style(calendar: Calendar, locale: Locale) -> Date.FormatStyle {
        Date.FormatStyle(date: .omitted, time: .omitted, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
    }
}
