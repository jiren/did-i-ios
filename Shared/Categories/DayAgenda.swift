import Foundation

/// What Today shows for one day and filter (`Main.dc.html`'s `renderVals`): the 7-day strip, the due categories
/// with their tasks, the progress bar and the Today tab's ring.
nonisolated struct DayAgenda: Equatable, Sendable {
    static let stripLength = 7
    static let maximumDots = 3

    /// A task on a day, as a tile or a row.
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
        /// Not done first, then done, each in the category's order.
        var tasks: [Tile]
        /// Every task logged, on today (a later day is never all done).
        var isAllDone: Bool

        var id: UUID { category.id }
        var doneCount: Int { tasks.filter(\.isDone).count }
        /// "2/4".
        var progressText: String { "\(doneCount)/\(tasks.count)" }
        /// The newest log among its tasks, for "All done · last 8:42 AM".
        var lastLog: LogRecord? { tasks.compactMap(\.log).max { $0.date < $1.date } }
    }

    struct StripDay: Identifiable, Equatable, Sendable {
        var day: CalendarDay
        /// "Today", then one letter: "S", "S", "M"…
        var weekdayText: String
        var dayNumber: Int
        /// The colours of up to three non-daily categories due that day.
        var dots: [TileSwatch]
        var isToday: Bool
        var isSelected: Bool
        /// "Sat, Oct 31, also due: Bin night, Home safety".
        var accessibilityLabel: String

        var id: CalendarDay { day }
    }

    /// The progress bar's pill.
    enum Pill: Equatable, Sendable {
        case left(Int), allClear, free, upcoming

        var text: String {
            switch self {
            case .left(let count): String(localized: "\(count) left")
            case .allClear: String(localized: "All clear")
            case .free: String(localized: "Free")
            case .upcoming: String(localized: "Upcoming")
            }
        }
    }

    struct Progress: Equatable, Sendable {
        /// The filter's name, else "Today", else the weekday ("Sat").
        var scope: String
        /// "2 of 6 done", "4 tasks planned", "Nothing due".
        var main: String
        var pill: Pill
        /// One per task in the sections' order; a done one fills with its tile colour.
        var segments: [Tile]

        var isAllClear: Bool { pill == .allClear }
    }

    let today: CalendarDay
    let selectedDay: CalendarDay
    /// The category shown alone, or nil for All.
    let filter: CategoryRecord?
    /// "Today", or the weekday ("Sat").
    let dayTitle: String
    /// "Fri, Oct 30" today, else "Oct 31".
    let daySub: String
    let strip: [StripDay]
    let sections: [Section]
    let progress: Progress
    /// "No tasks scheduled for Sat, Oct 31." when no section is due, else nil.
    let nothingDueText: String?
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
        let isToday = selected == today
        let categories = categories.sorted { ($0.order, $0.name) < ($1.order, $1.name) }
        let filter = categories.first { $0.id == filterID }
        let tasksByCategory = Self.tasksByCategory(categories: categories, checks: checks)
        let style = Date.FormatStyle(date: .omitted, time: .omitted, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
        let weekday = selected.noon(in: calendar).formatted(style.weekday(.abbreviated))
        let selectedDate = RepeatRule.shortDate(selected, calendar: calendar, locale: locale)

        self.today = today
        self.selectedDay = selected
        self.filter = filter
        dayTitle = isToday ? String(localized: "Today") : weekday
        daySub = isToday ? selectedDate : selected.noon(in: calendar).formatted(RepeatRule.monthDay(calendar: calendar, locale: locale))

        var letters = calendar
        letters.locale = locale
        strip = (0..<Self.stripLength).map { offset in
            let stripDay = today.adding(days: offset, calendar: calendar)
            let extra = categories.filter { $0.rule != .daily && $0.rule.isDue(on: stripDay, calendar: calendar) }
            let name = RepeatRule.shortDate(stripDay, calendar: calendar, locale: locale)
            let names = extra.map(\.name).joined(separator: ", ")
            return StripDay(
                day: stripDay,
                weekdayText: offset == 0
                    ? String(localized: "Today")
                    : letters.veryShortStandaloneWeekdaySymbols[stripDay.weekday(in: calendar) - 1],
                dayNumber: stripDay.day,
                dots: extra.prefix(Self.maximumDots).map(\.colour),
                isToday: offset == 0,
                isSelected: stripDay == selected,
                accessibilityLabel: extra.isEmpty ? name : String(localized: "\(name), also due: \(names)")
            )
        }

        let selectedLogs = Self.newestLogs(in: boundary.interval(of: selected), logs: logs)
        sections = categories
            .filter { (filter == nil || $0.id == filter?.id) && $0.rule.isDue(on: selected, calendar: calendar) }
            .map { category in
                let tasks = (tasksByCategory[category.id] ?? []).map { task in
                    Tile(check: task.check, swatch: task.swatch, log: selectedLogs[task.check.id])
                }
                return Section(
                    category: category,
                    repeatLabel: category.rule.label(calendar: calendar, locale: locale),
                    tasks: tasks.filter { !$0.isDone } + tasks.filter(\.isDone),
                    isAllDone: isToday && !tasks.isEmpty && tasks.allSatisfy(\.isDone)
                )
            }

        let segments = sections.flatMap(\.tasks)
        let doneCount = segments.filter(\.isDone).count
        let total = segments.count
        let pill: Pill
        let main: String
        if total == 0 {
            pill = .free
            main = String(localized: "Nothing due")
        } else if isToday {
            pill = doneCount == total ? .allClear : .left(total - doneCount)
            main = String(localized: "\(doneCount) of \(total) done")
        } else {
            pill = .upcoming
            main = total == 1 ? String(localized: "1 task planned") : String(localized: "\(total) tasks planned")
        }
        progress = Progress(
            scope: filter?.name ?? (isToday ? String(localized: "Today") : weekday),
            main: main,
            pill: pill,
            segments: segments
        )

        if sections.isEmpty {
            nothingDueText = filter.map {
                String(localized: "\($0.name) isn’t due on \(selectedDate). The dots on the days above show when it is.")
            } ?? String(localized: "No tasks scheduled for \(selectedDate).")
        } else {
            nothingDueText = nil
        }

        let todayLogs = isToday ? selectedLogs : Self.newestLogs(in: boundary.interval(of: today), logs: logs)
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
}
