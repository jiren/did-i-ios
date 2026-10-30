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
