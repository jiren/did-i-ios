import Foundation

/// A date on the calendar with no time or time zone ("Nov 6"), for repeat rules and the 7-day strip.
nonisolated struct CalendarDay: Hashable, Comparable, Codable, Sendable {
    var year: Int
    var month: Int
    var day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The calendar day `date` falls on in `calendar`'s time zone.
    init(_ date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// Noon on this day, a time every day has whatever DST does.
    func noon(in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? .distantPast
    }

    func adding(days: Int, calendar: Calendar) -> CalendarDay {
        CalendarDay(calendar.date(byAdding: .day, value: days, to: noon(in: calendar)) ?? noon(in: calendar), calendar: calendar)
    }

    /// Whole days from this day to `other` (negative when `other` is earlier).
    func days(to other: CalendarDay, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: noon(in: calendar), to: other.noon(in: calendar)).day ?? 0
    }

    /// 1 (Sunday) to 7 (Saturday), as `Calendar` counts weekdays.
    func weekday(in calendar: Calendar) -> Int {
        calendar.component(.weekday, from: noon(in: calendar))
    }

    func numberOfDaysInMonth(calendar: Calendar) -> Int {
        calendar.range(of: .day, in: .month, for: noon(in: calendar))?.count ?? 31
    }

    /// The 1st of this day's month.
    var firstOfMonth: CalendarDay { CalendarDay(year: year, month: month, day: 1) }

    /// The first day of this day's week, for a week starting on `firstWeekday` (1 is Sunday).
    func weekStart(firstWeekday: Int, calendar: Calendar) -> CalendarDay {
        adding(days: -((weekday(in: calendar) - firstWeekday + 7) % 7), calendar: calendar)
    }

    /// Whole months from this day's month to `other`'s (negative when `other` is earlier).
    func months(to other: CalendarDay, calendar: Calendar) -> Int {
        calendar.dateComponents([.month], from: firstOfMonth.noon(in: calendar), to: other.firstOfMonth.noon(in: calendar)).month ?? 0
    }

    /// Whole years from this day's year to `other`'s (negative when `other` is earlier).
    func years(to other: CalendarDay, calendar: Calendar) -> Int {
        let start = CalendarDay(year: year, month: 1, day: 1).noon(in: calendar)
        let end = CalendarDay(year: other.year, month: 1, day: 1).noon(in: calendar)
        return calendar.dateComponents([.year], from: start, to: end).year ?? 0
    }

    /// This day's month moved by `months`, on its 1st.
    func addingMonths(_ months: Int, calendar: Calendar) -> CalendarDay {
        let first = firstOfMonth.noon(in: calendar)
        return CalendarDay(calendar.date(byAdding: .month, value: months, to: first) ?? first, calendar: calendar).firstOfMonth
    }

    /// `day` of `month` in `year`, or the month's last day when it has fewer days.
    static func clamped(year: Int, month: Int, day: Int, calendar: Calendar) -> CalendarDay {
        let first = CalendarDay(year: year, month: month, day: 1)
        return CalendarDay(year: year, month: month, day: min(max(day, 1), first.numberOfDaysInMonth(calendar: calendar)))
    }

    /// The `ordinal` (1 to 4, or -1 for the last) `weekday` of `month` in `year`: "the first Monday of November".
    static func nth(weekday: Int, ordinal: Int, year: Int, month: Int, calendar: Calendar) -> CalendarDay {
        let first = CalendarDay(year: year, month: month, day: 1)
        let length = first.numberOfDaysInMonth(calendar: calendar)
        if ordinal < 0 {
            let last = CalendarDay(year: year, month: month, day: length)
            return CalendarDay(year: year, month: month, day: length - (last.weekday(in: calendar) - weekday + 7) % 7)
        }
        let day = 1 + (weekday - first.weekday(in: calendar) + 7) % 7 + 7 * (min(max(ordinal, 1), 4) - 1)
        return CalendarDay(year: year, month: month, day: day)
    }
}

nonisolated extension DayBoundary {
    /// The calendar day the "day" containing `date` belongs to (1 AM with a 5 AM start is the evening before).
    func calendarDay(containing date: Date) -> CalendarDay {
        CalendarDay(day(containing: date).start, calendar: calendar)
    }

    /// The span of `day`, from its start to the next day's start.
    func interval(of day: CalendarDay) -> DateInterval {
        self.day(containing: day.noon(in: calendar))
    }
}
