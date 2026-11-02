import Foundation

/// The Stats screen's time range (`Stats.dc.html`).
nonisolated enum StatsRange: String, CaseIterable, Identifiable, Sendable {
    case week, month, year

    var id: Self { self }

    var title: String {
        switch self {
        case .week: String(localized: "Week")
        case .month: String(localized: "Month")
        case .year: String(localized: "Year")
        }
    }

    /// What Second-guesses compares with: "last week".
    var previousLabel: String {
        switch self {
        case .week: String(localized: "last week")
        case .month: String(localized: "last month")
        case .year: String(localized: "last year")
        }
    }
}

nonisolated enum StatsRules {
    /// A log this soon after the same task's previous log is a re-log: a second guess.
    static let recheckWindow: TimeInterval = 30 * 60
}

/// Everything Stats needs from the store, indexed once, so each range's report is cheap.
nonisolated struct StatsHistory: Sendable {
    /// A category's tasks, with the first day each one counts as due.
    fileprivate struct Group: Sendable {
        var category: CategoryRecord?
        var rule: RepeatRule
        var tasks: [(id: UUID, firstDueDay: CalendarDay)]
    }

    fileprivate let boundary: DayBoundary
    fileprivate let categories: [CategoryRecord]
    fileprivate let checks: [CheckRecord]
    fileprivate let groups: [Group]
    /// Oldest first.
    fileprivate let logs: [LogRecord]
    /// Each re-log, oldest first.
    fileprivate let relogs: [LogRecord]
    fileprivate let loggedChecks: [CalendarDay: Set<UUID>]

    init(categories: [CategoryRecord], checks: [CheckRecord], logs: [LogRecord], boundary: DayBoundary) {
        let known = Set(checks.map(\.id))
        let logs = logs.filter { known.contains($0.checkID) }.sorted { $0.date < $1.date }
        let categories = categories.sorted { ($0.order, $0.name) < ($1.order, $1.name) }

        var firstLogs: [UUID: Date] = [:]
        var previous: [UUID: Date] = [:]
        var relogs: [LogRecord] = []
        var loggedChecks: [CalendarDay: Set<UUID>] = [:]
        for log in logs {
            if firstLogs[log.checkID] == nil { firstLogs[log.checkID] = log.date }
            if let last = previous[log.checkID], log.date.timeIntervalSince(last) <= StatsRules.recheckWindow {
                relogs.append(log)
            }
            previous[log.checkID] = log.date
            loggedChecks[boundary.calendarDay(containing: log.date), default: []].insert(log.checkID)
        }

        // A task in an unknown category counts as Daily's, as `DueTasks` has it.
        let fallback = categories.first(where: \.isDefault)?.id ?? CategoryDefaults.dailyID
        let categoryIDs = Set(categories.map(\.id))
        let grouped = Dictionary(grouping: checks) { categoryIDs.contains($0.categoryID) ? $0.categoryID : fallback }
        var groups: [Group] = categories.map { Group(category: $0, rule: $0.rule, tasks: []) }
        if !categoryIDs.contains(fallback), grouped[fallback] != nil {
            groups.append(Group(category: nil, rule: .daily, tasks: []))
        }
        for index in groups.indices {
            let id = groups[index].category?.id ?? fallback
            groups[index].tasks = (grouped[id] ?? []).map { check in
                let start = min(check.createdAt, firstLogs[check.id] ?? check.createdAt)
                return (check.id, boundary.calendarDay(containing: start))
            }
        }

        self.boundary = boundary
        self.categories = categories
        self.checks = checks
        self.groups = groups
        self.logs = logs
        self.relogs = relogs
        self.loggedChecks = loggedChecks
    }

    /// Tasks due and done on a day, per group.
    fileprivate func tally(on day: CalendarDay) -> [Tally] {
        let logged = loggedChecks[day] ?? []
        return groups.map { group in
            guard !group.tasks.isEmpty, group.rule.isDue(on: day, calendar: boundary.calendar) else { return Tally() }
            var tally = Tally()
            for task in group.tasks where task.firstDueDay <= day {
                tally.due += 1
                if logged.contains(task.id) { tally.done += 1 }
            }
            return tally
        }
    }

    /// The current run of days with every due task logged. A day with nothing due is skipped, and an unfinished
    /// today doesn't break the run. The walk stops at the oldest log, before which nothing can be complete.
    func streak(today: CalendarDay) -> Int {
        guard let oldest = logs.first.map({ boundary.calendarDay(containing: $0.date) }) else { return 0 }
        var streak = 0
        var day = today
        while day >= oldest {
            let total = tally(on: day).reduce(into: Tally()) { $0.add($1) }
            if total.due > 0 {
                if total.done == total.due {
                    streak += 1
                } else if day != today {
                    break
                }
            }
            day = day.adding(days: -1, calendar: boundary.calendar)
        }
        return streak
    }
}

/// Tasks due and done over some span.
private nonisolated struct Tally {
    var due = 0
    var done = 0

    mutating func add(_ other: Tally) {
        due += other.due
        done += other.done
    }

    /// Nil with nothing due. Only an all-done span reads 100%, however close the rest rounds.
    var percent: Int? { due == 0 ? nil : StatsReport.percent(done, of: due) }
}

/// What the Stats screen shows for one range (`Stats.dc.html`). Past shares use each category's current schedule,
/// since no history of schedule changes is kept.
nonisolated struct StatsReport: Equatable, Sendable {
    struct Bar: Identifiable, Equatable, Sendable {
        /// Unique, unlike `label`: the Year's letters repeat.
        let id: String
        /// Under the bar: "Tue", "W1", "J".
        var label: String
        /// "Tue, Oct 27", "Oct 5–11", "Nov so far".
        var detail: String
        /// Nil with nothing due.
        var percent: Int?

        /// "100% logged" or "Nothing due".
        var valueText: String {
            percent.map { String(localized: "\($0)% logged") } ?? String(localized: "Nothing due")
        }

        /// "Tue, Oct 27 · 100% logged".
        var tip: String { "\(detail) · \(valueText)" }
    }

    /// Second-guesses against the previous period of the same length.
    enum Trend: Equatable, Sendable {
        case down(percent: Int)
        case up(percent: Int)
        case same
        /// Nothing to compare with: no re-logs last period. Holds this period's count.
        case noComparison(count: Int)
    }

    struct CategoryRow: Identifiable, Equatable, Sendable {
        var category: CategoryRecord
        var percent: Int

        var id: UUID { category.id }
    }

    /// How You Log's rows. The design draws the first three; `.control` joins the Action Button because the two
    /// can't be told apart.
    enum Method: String, CaseIterable, Identifiable, Sendable {
        case actionButton, lockScreenWidget, app, homeScreenWidget, siriAndShortcuts, notification

        var id: Self { self }

        init(_ source: LogSource) {
            switch source {
            case .actionButton, .control: self = .actionButton
            case .lockScreenWidget: self = .lockScreenWidget
            case .app: self = .app
            case .homeScreenWidget: self = .homeScreenWidget
            case .siri, .shortcut: self = .siriAndShortcuts
            case .notification: self = .notification
            }
        }

        var label: String {
            switch self {
            case .actionButton: String(localized: "Action Button")
            case .lockScreenWidget: String(localized: "Lock Screen widget")
            case .app: String(localized: "In the app")
            case .homeScreenWidget: String(localized: "Home Screen widget")
            case .siriAndShortcuts: String(localized: "Siri & Shortcuts")
            case .notification: String(localized: "Notification")
            }
        }
    }

    struct MethodRow: Identifiable, Equatable, Sendable {
        var method: Method
        var count: Int
        var percent: Int

        var id: Method { method }
    }

    struct MostRechecked: Equatable, Sendable {
        var name: String
        var kind: CheckKind
        var count: Int
    }

    let range: StatsRange
    /// Whether any log exists at all; without one the screen shows its empty card.
    let hasLogs: Bool
    let streak: Int
    let trend: Trend
    /// Mean of the bars with something due.
    let average: Int?
    let bars: [Bar]
    let categories: [CategoryRow]
    let methods: [MethodRow]
    let mostRechecked: MostRechecked?
    /// Logs in the range that still have their photo; Keep photos clears older ones.
    let photosKept: Int
    /// "8–9 AM", or nil with no logs in the range.
    let busiestHour: String?

    init(
        range: StatsRange,
        categories: [CategoryRecord],
        checks: [CheckRecord],
        logs: [LogRecord],
        now: Date,
        boundary: DayBoundary,
        locale: Locale
    ) {
        self.init(
            range: range,
            history: StatsHistory(categories: categories, checks: checks, logs: logs, boundary: boundary),
            now: now,
            locale: locale
        )
    }

    init(range: StatsRange, history: StatsHistory, now: Date, locale: Locale) {
        let boundary = history.boundary
        let calendar = boundary.calendar
        let today = boundary.calendarDay(containing: now)
        let spans = StatsPeriods.spans(for: range, today: today, calendar: calendar, locale: locale)
        let first = spans.first?.first ?? today
        let interval = DateInterval(start: boundary.interval(of: first).start, end: boundary.interval(of: today).end)

        // One tally per bar, and per group across all of them.
        var groupTotals = Array(repeating: Tally(), count: history.groups.count)
        var bars: [Bar] = []
        for (index, span) in spans.enumerated() {
            var total = Tally()
            var day = span.first
            while day <= span.last {
                for (group, tally) in history.tally(on: day).enumerated() {
                    total.add(tally)
                    groupTotals[group].add(tally)
                }
                day = day.adding(days: 1, calendar: calendar)
            }
            bars.append(Bar(id: String(index), label: span.label, detail: span.detail, percent: total.percent))
        }
        let shown = bars.compactMap(\.percent)

        self.range = range
        hasLogs = !history.logs.isEmpty
        streak = history.streak(today: today)
        self.bars = bars
        average = shown.isEmpty ? nil : Int((Double(shown.reduce(0, +)) / Double(shown.count)).rounded())
        self.categories = zip(history.groups, groupTotals).compactMap { group, tally in
            guard let category = group.category, let percent = tally.percent else { return nil }
            return CategoryRow(category: category, percent: percent)
        }

        let inRange = history.logs.filter { interval.contains($0.date) && $0.date < interval.end }
        let relogs = history.relogs.filter { interval.contains($0.date) && $0.date < interval.end }
        let length = first.days(to: today, calendar: calendar) + 1
        let previousStart = boundary.interval(of: first.adding(days: -length, calendar: calendar)).start
        let previousCount = history.relogs.filter { $0.date >= previousStart && $0.date < interval.start }.count
        trend = Self.trend(current: relogs.count, previous: previousCount)

        mostRechecked = Self.mostRechecked(relogs, history: history)
        methods = Self.methods(inRange)
        photosKept = inRange.filter(\.hasPhoto).count
        busiestHour = Self.busiestHour(inRange, calendar: calendar, locale: locale)
    }

    /// `part` of `whole` as a whole percent, keeping 100% for all of it and 0% for none of it.
    static func percent(_ part: Int, of whole: Int) -> Int {
        guard whole > 0 else { return 0 }
        let rounded = Int((Double(part) / Double(whole) * 100).rounded())
        if part == whole { return 100 }
        return part == 0 ? 0 : min(max(rounded, 1), 99)
    }

    static func trend(current: Int, previous: Int) -> Trend {
        guard previous > 0 else { return .noComparison(count: current) }
        guard current != previous else { return .same }
        let change = Int((Double(abs(current - previous)) / Double(previous) * 100).rounded())
        return current < previous ? .down(percent: change) : .up(percent: change)
    }

    /// The task with the most re-logs; a tie goes to the earlier one in the list.
    private static func mostRechecked(_ relogs: [LogRecord], history: StatsHistory) -> MostRechecked? {
        let counts = Dictionary(grouping: relogs, by: \.checkID).mapValues(\.count)
        guard let most = counts.values.max(), let check = history.checks.first(where: { counts[$0.id] == most }) else { return nil }
        let titles = CheckLabels.titles(for: history.checks, categories: history.categories)
        return MostRechecked(name: titles[check.id] ?? check.name, kind: check.kind, count: most)
    }

    private static func methods(_ logs: [LogRecord]) -> [MethodRow] {
        let counts = Dictionary(grouping: logs) { Method($0.source) }.mapValues(\.count)
        return Method.allCases.compactMap { method in
            guard let count = counts[method] else { return nil }
            return MethodRow(method: method, count: count, percent: percent(count, of: logs.count))
        }
    }

    /// The hour of the day with the most logs; a tie goes to the earlier hour.
    private static func busiestHour(_ logs: [LogRecord], calendar: Calendar, locale: Locale) -> String? {
        var counts = Array(repeating: 0, count: 24)
        for log in logs { counts[calendar.component(.hour, from: log.date)] += 1 }
        guard let most = counts.max(), most > 0, let hour = counts.firstIndex(of: most) else { return nil }
        return hourRange(startingAt: hour, calendar: calendar, locale: locale)
    }

    /// "8–9 AM", "11 AM–12 PM", "11 PM–12 AM"; "08–09" where the clock is 24-hour.
    static func hourRange(startingAt hour: Int, calendar: Calendar, locale: Locale) -> String {
        let style = Date.FormatStyle(date: .omitted, time: .omitted, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .hour(.defaultDigits(amPM: .abbreviated))
        func text(_ hour: Int) -> String {
            // A mid-January day, away from most DST changes; only the hour's text matters here.
            let date = calendar.date(from: DateComponents(year: 2028, month: 1, day: 15, hour: hour)) ?? .distantPast
            return date.formatted(style)
        }
        let start = text(hour)
        let end = text((hour + 1) % 24)
        let isDigit: (Character) -> Bool = { $0.isNumber }
        let startPeriod = String(start.drop(while: isDigit))
        let endPeriod = String(end.drop(while: isDigit))
        if !startPeriod.isEmpty, startPeriod == endPeriod {
            return "\(start.prefix(while: isDigit))–\(end)"
        }
        return "\(start)–\(end)"
    }
}

/// The spans behind a range's bars.
nonisolated enum StatsPeriods {
    struct Span: Equatable, Sendable {
        var first: CalendarDay
        var last: CalendarDay
        var label: String
        var detail: String
    }

    static let weekDays = 7
    static let monthWeeks = 4
    static let yearMonths = 12

    static func spans(for range: StatsRange, today: CalendarDay, calendar: Calendar, locale: Locale) -> [Span] {
        switch range {
        case .week: week(today: today, calendar: calendar, locale: locale)
        case .month: month(today: today, calendar: calendar, locale: locale)
        case .year: year(today: today, calendar: calendar, locale: locale)
        }
    }

    /// Seven days ending today.
    private static func week(today: CalendarDay, calendar: Calendar, locale: Locale) -> [Span] {
        let style = Date.FormatStyle(date: .omitted, time: .omitted, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .weekday(.abbreviated)
        return (0..<weekDays).map { index in
            let day = today.adding(days: index - (weekDays - 1), calendar: calendar)
            return Span(
                first: day, last: day,
                label: day.noon(in: calendar).formatted(style),
                detail: day == today ? String(localized: "Today") : RepeatRule.shortDate(day, calendar: calendar, locale: locale)
            )
        }
    }

    /// Four whole calendar weeks and this week so far: "W1"…"W4", "Now".
    private static func month(today: CalendarDay, calendar: Calendar, locale: Locale) -> [Span] {
        let intoWeek = (today.weekday(in: calendar) - calendar.firstWeekday + 7) % 7
        let thisWeek = today.adding(days: -intoWeek, calendar: calendar)
        let earlier = (0..<monthWeeks).map { index in
            let first = thisWeek.adding(days: (index - monthWeeks) * 7, calendar: calendar)
            let last = first.adding(days: 6, calendar: calendar)
            return Span(
                first: first, last: last,
                label: String(localized: "W\(index + 1)"),
                detail: dateSpan(first, last, calendar: calendar, locale: locale)
            )
        }
        return earlier + [Span(first: thisWeek, last: today, label: String(localized: "Now"), detail: String(localized: "This week"))]
    }

    /// Twelve calendar months ending with this one so far.
    private static func year(today: CalendarDay, calendar: Calendar, locale: Locale) -> [Span] {
        var letters = calendar
        letters.locale = locale
        let base = Date.FormatStyle(date: .omitted, time: .omitted, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .month(.abbreviated)
        return (0..<yearMonths).map { index in
            let months = today.year * 12 + (today.month - 1) + index - (yearMonths - 1)
            let first = CalendarDay(year: months / 12, month: months % 12 + 1, day: 1)
            let isNow = index == yearMonths - 1
            let last = isNow ? today : CalendarDay(year: first.year, month: first.month, day: first.numberOfDaysInMonth(calendar: calendar))
            let date = first.noon(in: calendar)
            let detail: String
            if isNow {
                detail = String(localized: "\(date.formatted(base)) so far")
            } else if first.year == today.year {
                detail = date.formatted(base)
            } else {
                detail = date.formatted(base.year())
            }
            return Span(first: first, last: last, label: letters.veryShortStandaloneMonthSymbols[first.month - 1], detail: detail)
        }
    }

    /// "Oct 5–11", or "Oct 26–Nov 1" across two months.
    private static func dateSpan(_ first: CalendarDay, _ last: CalendarDay, calendar: Calendar, locale: Locale) -> String {
        let monthDay = RepeatRule.monthDay(calendar: calendar, locale: locale)
        let start = first.noon(in: calendar).formatted(monthDay)
        let end = first.month == last.month ? String(last.day) : last.noon(in: calendar).formatted(monthDay)
        return "\(start)–\(end)"
    }
}
