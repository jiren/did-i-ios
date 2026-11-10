import Foundation

/// A calendar-style repeat (Phase 26), like Calendar's Custom: every `interval` days, weeks, months or years, from
/// `start`, until `end`. Each month (or year) has exactly one occurrence, so counting them is arithmetic, not a scan.
nonisolated struct CustomRepeat: Hashable, Sendable {
    enum Frequency: Hashable, Sendable {
        case daily
        /// 1 (Sunday) to 7; at least one.
        case weekly(weekdays: Set<Int>)
        case monthly(MonthPosition)
        /// `month` is 1 to 12.
        case yearly(month: Int, MonthPosition)
    }

    /// Where in a month it falls.
    enum MonthPosition: Hashable, Sendable {
        /// 1 to 31; past the month's end it falls on the last day.
        case day(Int)
        /// "The first Monday", "the last Friday".
        case weekday(Int, WeekOrdinal)
    }

    enum WeekOrdinal: Int, CaseIterable, Hashable, Sendable {
        case first = 1, second = 2, third = 3, fourth = 4, last = -1
    }

    /// The four units of "Every {n} …", as stored and as the editor names them.
    enum Unit: String, CaseIterable, Hashable, Sendable {
        case days, weeks, months, years
    }

    enum End: Hashable, Sendable {
        case never
        /// The last day it can fall on, inclusive.
        case on(CalendarDay)
        /// After this many times (1 or more).
        case after(Int)
    }

    static let intervalRange = 1...99
    static let countRange = 1...999

    var frequency: Frequency
    var interval: Int
    var start: CalendarDay
    var end: End
    /// The calendar's first weekday when it was saved, so weeks keep their grouping if the region changes.
    var weekStart: Int

    init(frequency: Frequency, interval: Int = 1, start: CalendarDay, end: End = .never, weekStart: Int = 1) {
        self.frequency = frequency
        self.interval = interval
        self.start = start
        self.end = end
        self.weekStart = weekStart
    }

    var unit: Unit {
        switch frequency {
        case .daily: .days
        case .weekly: .weeks
        case .monthly: .months
        case .yearly: .years
        }
    }

    /// Clamped into range: an interval of 1–99, at least one weekday, a real month and day, an end on or after the
    /// start, and at least one time.
    func normalized() -> CustomRepeat {
        var copy = self
        copy.interval = min(max(interval, Self.intervalRange.lowerBound), Self.intervalRange.upperBound)
        copy.weekStart = RepeatRule.clampedWeekday(weekStart)
        switch frequency {
        case .daily:
            break
        case .weekly(let weekdays):
            let valid = weekdays.filter { (1...7).contains($0) }
            copy.frequency = .weekly(weekdays: valid.isEmpty ? [1] : valid)
        case .monthly(let position):
            copy.frequency = .monthly(position.normalized)
        case .yearly(let month, let position):
            copy.frequency = .yearly(month: min(max(month, 1), 12), position.normalized)
        }
        switch end {
        case .never: break
        case .on(let last): copy.end = .on(max(last, start))
        case .after(let count): copy.end = .after(min(max(count, Self.countRange.lowerBound), Self.countRange.upperBound))
        }
        return copy
    }

    // MARK: - Evaluation

    func isDue(on day: CalendarDay, calendar: Calendar) -> Bool {
        guard day >= start, matchesPattern(day, calendar: calendar) else { return false }
        return isWithinEnd(day, calendar: calendar)
    }

    /// The first due day from `day` on, or nil once it has ended.
    func nextDueDay(onOrAfter day: CalendarDay, calendar: Calendar) -> CalendarDay? {
        let from = max(day, start)
        guard let candidate = nextOccurrence(onOrAfter: from, calendar: calendar) else { return nil }
        return isWithinEnd(candidate, calendar: calendar) ? candidate : nil
    }

    /// Whether it can't come up any more from `day` on.
    func hasEnded(before day: CalendarDay, calendar: Calendar) -> Bool {
        if case .never = end { return false }
        return nextDueDay(onOrAfter: day, calendar: calendar) == nil
    }

    /// How many times it fell before `day`, from the start; `day` must be one of its days.
    func occurrenceIndex(of day: CalendarDay, calendar: Calendar) -> Int {
        switch frequency {
        case .daily:
            return start.days(to: day, calendar: calendar) / interval
        case .weekly(let weekdays):
            let firstWeek = start.weekStart(firstWeekday: weekStart, calendar: calendar)
            let week = day.weekStart(firstWeekday: weekStart, calendar: calendar)
            let periods = firstWeek.days(to: week, calendar: calendar) / 7 / interval
            return periods * weekdays.count
                + countBefore(day, in: weekdays, calendar: calendar)
                - countBefore(start, in: weekdays, calendar: calendar)
        case .monthly(let position):
            let periods = start.months(to: day, calendar: calendar) / interval
            let first = position.day(year: start.year, month: start.month, calendar: calendar)
            return periods - (first < start ? 1 : 0)
        case .yearly(let month, let position):
            let periods = start.years(to: day, calendar: calendar) / interval
            let first = position.day(year: start.year, month: month, calendar: calendar)
            return periods - (first < start ? 1 : 0)
        }
    }

    private func isWithinEnd(_ day: CalendarDay, calendar: Calendar) -> Bool {
        switch end {
        case .never: true
        case .on(let last): day <= last
        case .after(let count): occurrenceIndex(of: day, calendar: calendar) < count
        }
    }

    /// On or after the start, in an aligned period, on the pattern's day; the end isn't checked.
    private func matchesPattern(_ day: CalendarDay, calendar: Calendar) -> Bool {
        switch frequency {
        case .daily:
            return start.days(to: day, calendar: calendar) % interval == 0
        case .weekly(let weekdays):
            guard weekdays.contains(day.weekday(in: calendar)) else { return false }
            let firstWeek = start.weekStart(firstWeekday: weekStart, calendar: calendar)
            let week = day.weekStart(firstWeekday: weekStart, calendar: calendar)
            return (firstWeek.days(to: week, calendar: calendar) / 7) % interval == 0
        case .monthly(let position):
            guard start.months(to: day, calendar: calendar) % interval == 0 else { return false }
            return day == position.day(year: day.year, month: day.month, calendar: calendar)
        case .yearly(let month, let position):
            guard day.month == month, start.years(to: day, calendar: calendar) % interval == 0 else { return false }
            return day == position.day(year: day.year, month: month, calendar: calendar)
        }
    }

    /// The first day on or after `from` (itself on or after the start) that matches, ignoring the end.
    private func nextOccurrence(onOrAfter from: CalendarDay, calendar: Calendar) -> CalendarDay? {
        switch frequency {
        case .daily:
            let offset = start.days(to: from, calendar: calendar) % interval
            return from.adding(days: offset == 0 ? 0 : interval - offset, calendar: calendar)
        case .weekly:
            // At most one aligned week ahead, plus the rest of this one.
            for ahead in 0..<(7 * interval + 7) {
                let candidate = from.adding(days: ahead, calendar: calendar)
                if matchesPattern(candidate, calendar: calendar) { return candidate }
            }
            return nil
        case .monthly(let position):
            let elapsed = start.months(to: from, calendar: calendar)
            var periods = (elapsed + interval - 1) / interval * interval
            for _ in 0..<2 {
                let month = start.addingMonths(periods, calendar: calendar)
                let candidate = position.day(year: month.year, month: month.month, calendar: calendar)
                if candidate >= from { return candidate }
                periods += interval
            }
            return nil
        case .yearly(let month, let position):
            let elapsed = start.years(to: from, calendar: calendar)
            var periods = (elapsed + interval - 1) / interval * interval
            for _ in 0..<2 {
                let candidate = position.day(year: start.year + periods, month: month, calendar: calendar)
                if candidate >= from { return candidate }
                periods += interval
            }
            return nil
        }
    }

    /// The chosen weekdays that come before `day`'s weekday in its week.
    private func countBefore(_ day: CalendarDay, in weekdays: Set<Int>, calendar: Calendar) -> Int {
        let position = { (weekday: Int) in (weekday - weekStart + 7) % 7 }
        let own = position(day.weekday(in: calendar))
        return weekdays.count { position($0) < own }
    }
}

nonisolated extension CustomRepeat.MonthPosition {
    /// Its day in `month` of `year`.
    func day(year: Int, month: Int, calendar: Calendar) -> CalendarDay {
        switch self {
        case .day(let day):
            CalendarDay.clamped(year: year, month: month, day: day, calendar: calendar)
        case .weekday(let weekday, let ordinal):
            CalendarDay.nth(weekday: weekday, ordinal: ordinal.rawValue, year: year, month: month, calendar: calendar)
        }
    }

    var normalized: Self {
        switch self {
        case .day(let day): .day(min(max(day, 1), 31))
        case .weekday(let weekday, let ordinal): .weekday(RepeatRule.clampedWeekday(weekday), ordinal)
        }
    }
}
