import Foundation

/// Every way the design writes a log's time: "8:42 AM", "2h 27m ago", "Today, 8:42 AM", "Thursday · 8:42:07 AM".
nonisolated struct RelativeTime: Sendable {
    var boundary: DayBoundary
    var locale: Locale

    init(boundary: DayBoundary = DayBoundary(), locale: Locale = .autoupdatingCurrent) {
        self.boundary = boundary
        self.locale = locale
    }

    private var calendar: Calendar { boundary.calendar }

    private func style(date: Date.FormatStyle.DateStyle, time: Date.FormatStyle.TimeStyle) -> Date.FormatStyle {
        Date.FormatStyle(date: date, time: time, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
    }

    /// "8:42 AM"
    func clockTime(_ date: Date) -> String {
        date.formatted(style(date: .omitted, time: .shortened))
    }

    /// "8:42:07 AM"
    func clockTimeWithSeconds(_ date: Date) -> String {
        date.formatted(style(date: .omitted, time: .standard))
    }

    /// "Just now", "12m ago", "2h ago", "2h 27m ago", "3d ago".
    func ago(_ date: Date, now: Date) -> String {
        let minutes = max(0, Int(now.timeIntervalSince(date) / 60))
        switch minutes {
        case 0: return String(localized: "Just now")
        case 1..<60: return String(localized: "\(minutes)m ago")
        case 60..<(24 * 60):
            let hours = minutes / 60, rest = minutes % 60
            return rest == 0 ? String(localized: "\(hours)h ago") : String(localized: "\(hours)h \(rest)m ago")
        default: return String(localized: "\(minutes / (24 * 60))d ago")
        }
    }

    /// "Today", "Yesterday", or "Tue, Oct 27".
    func dayName(_ date: Date, now: Date) -> String {
        if boundary.isInSameDay(date, as: now) { return String(localized: "Today") }
        if boundary.isInSameDay(date, as: boundary.previousDay(before: now).start) {
            return String(localized: "Yesterday")
        }
        var format = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
        format = format.weekday(.abbreviated).month(.abbreviated).day()
        return date.formatted(format)
    }

    /// "Today, 8:42 AM", "Yesterday, 10:58 PM".
    func dayAndTime(_ date: Date, now: Date) -> String {
        String(localized: "\(dayName(date, now: now)), \(clockTime(date))")
    }

    /// "Thursday"
    func weekday(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).weekday(.wide))
    }
}
