import Foundation

/// When a "day" starts, so a door checked at 1 AM can still count for the evening before.
nonisolated struct DayBoundary: Equatable, Sendable {
    static let latestStartHour = 5

    var calendar: Calendar
    /// 0 (midnight) to 5.
    var startHour: Int

    init(calendar: Calendar = .autoupdatingCurrent, startHour: Int = 0) {
        self.calendar = calendar
        self.startHour = min(max(startHour, 0), Self.latestStartHour)
    }

    /// The day that `date` falls in, from its start to the next day's start (23 or 25 hours across DST).
    func day(containing date: Date) -> DateInterval {
        var start = start(onCalendarDayOf: date)
        if date < start, let dayBefore = calendar.date(byAdding: .day, value: -1, to: date) {
            start = self.start(onCalendarDayOf: dayBefore)
        }
        let nextCalendarDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: start)) ?? start
        let end = self.start(onCalendarDayOf: nextCalendarDay)
        return DateInterval(start: start, end: max(end, start))
    }

    /// Whether `date` is in the same day as `reference` (the end is the next day's start, so it's excluded).
    func isInSameDay(_ date: Date, as reference: Date) -> Bool {
        let day = day(containing: reference)
        return date >= day.start && date < day.end
    }

    /// The day before the one `date` is in.
    func previousDay(before date: Date) -> DateInterval {
        day(containing: day(containing: date).start.addingTimeInterval(-1))
    }

    /// Wall-clock `startHour` on that calendar day (the next valid time if DST skips it).
    private func start(onCalendarDayOf date: Date) -> Date {
        let midnight = calendar.startOfDay(for: date)
        guard startHour > 0 else { return midnight }
        return calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: midnight) ?? midnight
    }
}
