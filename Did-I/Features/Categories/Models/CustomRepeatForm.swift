import Foundation

/// The Custom repeat card on New and Edit category, as edited (Phase 26). Every part keeps a value whichever unit is
/// chosen, so switching units back and forth loses nothing; `rule(weekStart:)` builds the rule.
nonisolated struct CustomRepeatForm: Equatable, Sendable {
    enum EndChoice: String, CaseIterable, Sendable {
        case never, onDate, after

        var title: String {
            switch self {
            case .never: String(localized: "Never")
            case .onDate: String(localized: "On a date")
            case .after: String(localized: "After")
            }
        }
    }

    /// Monthly and yearly: on a day of the month, or on "the first Monday".
    enum PositionChoice: String, CaseIterable, Sendable {
        case day, weekday

        var title: String {
            switch self {
            case .day: String(localized: "On day")
            case .weekday: String(localized: "On the")
            }
        }
    }

    var unit: CustomRepeat.Unit = .weeks
    var interval = 1
    /// Weekly: one or more, 1 (Sunday) to 7.
    var weekdays: Set<Int>
    /// Yearly: 1 to 12.
    var month: Int
    var positionChoice: PositionChoice = .day
    /// 1 to 31.
    var monthDay: Int
    var ordinal: CustomRepeat.WeekOrdinal
    var ordinalWeekday: Int
    private(set) var start: CalendarDay
    var endChoice: EndChoice = .never
    /// On or after `start`.
    private(set) var endDate: CalendarDay
    var endCount = 5
    /// A loaded rule's week start; new ones take the calendar's.
    var weekStart: Int?

    /// Starting on `start`, every week on its weekday; the other parts follow from it.
    init(start: CalendarDay, calendar: Calendar) {
        let weekday = start.weekday(in: calendar)
        self.start = start
        weekdays = [weekday]
        month = start.month
        monthDay = start.day
        ordinalWeekday = weekday
        ordinal = Self.ordinal(of: start, calendar: calendar)
        let threeMonths = calendar.date(byAdding: .month, value: 3, to: start.noon(in: calendar)) ?? start.noon(in: calendar)
        endDate = CalendarDay(threeMonths, calendar: calendar)
    }

    /// The same schedule as `rule`, so picking Custom after a preset starts from it: Every 2 weeks becomes every 2
    /// weeks from its anchor, On a date starts on that day.
    init(from rule: RepeatRule, today: CalendarDay, calendar: Calendar) {
        self.init(start: today, calendar: calendar)
        switch rule {
        case .daily:
            unit = .days
        case .weekly(let days):
            weekdays = days
        case .everyTwoWeeks(let weekday, let anchor):
            self = CustomRepeatForm(start: anchor, calendar: calendar)
            weekdays = [weekday]
            interval = 2
        case .monthly(let day):
            unit = .months
            monthDay = day
        case .yearly(let month, let day):
            unit = .years
            self.month = month
            monthDay = day
        case .once(let day):
            self = CustomRepeatForm(start: day, calendar: calendar)
            unit = .days
        case .custom(let custom):
            self = CustomRepeatForm(start: custom.start, calendar: calendar)
            load(custom)
        }
    }

    private mutating func load(_ custom: CustomRepeat) {
        unit = custom.unit
        interval = custom.interval
        weekStart = custom.weekStart
        let position: CustomRepeat.MonthPosition?
        switch custom.frequency {
        case .daily: position = nil
        case .weekly(let days): weekdays = days; position = nil
        case .monthly(let monthPosition): position = monthPosition
        case .yearly(let month, let monthPosition): self.month = month; position = monthPosition
        }
        switch position {
        case .day(let day): positionChoice = .day; monthDay = day
        case .weekday(let weekday, let ordinal): positionChoice = .weekday; ordinalWeekday = weekday; self.ordinal = ordinal
        case nil: break
        }
        switch custom.end {
        case .never: endChoice = .never
        case .on(let last): endChoice = .onDate; endDate = max(last, start)
        case .after(let count): endChoice = .after; endCount = count
        }
    }

    /// Moves the start; an end date before it moves along.
    mutating func setStart(_ day: CalendarDay) {
        start = day
        if endDate < day { endDate = day }
    }

    /// Never before the start.
    mutating func setEndDate(_ day: CalendarDay) {
        endDate = max(day, start)
    }

    func rule(weekStart defaultWeekStart: Int) -> RepeatRule {
        let position: CustomRepeat.MonthPosition = switch positionChoice {
        case .day: .day(monthDay)
        case .weekday: .weekday(ordinalWeekday, ordinal)
        }
        let frequency: CustomRepeat.Frequency = switch unit {
        case .days: .daily
        case .weeks: .weekly(weekdays: weekdays)
        case .months: .monthly(position)
        case .years: .yearly(month: month, position)
        }
        let end: CustomRepeat.End = switch endChoice {
        case .never: .never
        case .onDate: .on(endDate)
        case .after: .after(endCount)
        }
        let custom = CustomRepeat(
            frequency: frequency, interval: interval, start: start, end: end, weekStart: weekStart ?? defaultWeekStart
        )
        return .custom(custom.normalized())
    }

    // MARK: - Copy

    /// "Every week", "Every 3 weeks".
    var intervalText: String {
        let n = interval
        switch unit {
        case .days: return n == 1 ? String(localized: "Every day") : String(localized: "Every \(n) days")
        case .weeks: return n == 1 ? String(localized: "Every week") : String(localized: "Every \(n) weeks")
        case .months: return n == 1 ? String(localized: "Every month") : String(localized: "Every \(n) months")
        case .years: return n == 1 ? String(localized: "Every year") : String(localized: "Every \(n) years")
        }
    }

    /// "After 1 time", "After 5 times".
    var endCountText: String {
        endCount == 1 ? String(localized: "After 1 time") : String(localized: "After \(endCount) times")
    }

    static func unitTitle(_ unit: CustomRepeat.Unit) -> String {
        switch unit {
        case .days: String(localized: "Days")
        case .weeks: String(localized: "Weeks")
        case .months: String(localized: "Months")
        case .years: String(localized: "Years")
        }
    }

    static func ordinalTitle(_ ordinal: CustomRepeat.WeekOrdinal) -> String {
        switch ordinal {
        case .first: String(localized: "First")
        case .second: String(localized: "Second")
        case .third: String(localized: "Third")
        case .fourth: String(localized: "Fourth")
        case .last: String(localized: "Last")
        }
    }

    /// Which of its month's weekdays `day` is: the 1st–7th are the first, and a fifth one counts as the last.
    private static func ordinal(of day: CalendarDay, calendar: Calendar) -> CustomRepeat.WeekOrdinal {
        let week = (day.day - 1) / 7 + 1
        return CustomRepeat.WeekOrdinal(rawValue: week) ?? .last
    }
}
