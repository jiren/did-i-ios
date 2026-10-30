import Foundation

/// When a category is due (`Main.dc.html`'s `isDue` and `repeatLabel`, `NewCategory.dc.html`'s Repeat).
nonisolated enum RepeatRule: Hashable, Sendable {
    case daily
    /// On these weekdays, 1 (Sunday) to 7 (Saturday): one ("Every Friday") or several ("Every weekday").
    case weekly(weekdays: Set<Int>)
    /// Every other `weekday`, counted from `anchor`, the first day it was due.
    case everyTwoWeeks(weekday: Int, anchor: CalendarDay)
    /// `day` is 1 to 31; past the month's end it falls on the last day.
    case monthly(day: Int)
    /// Feb 29 falls on Feb 28 in other years.
    case yearly(month: Int, day: Int)
    /// Once, on that day.
    case once(CalendarDay)

    /// Monday to Friday.
    static let workingDays: Set<Int> = [2, 3, 4, 5, 6]
    static let weekendDays: Set<Int> = [1, 7]

    /// Weekly on one day.
    static func weekly(weekday: Int) -> RepeatRule {
        .weekly(weekdays: [clampedWeekday(weekday)])
    }

    /// Every other `weekday`, starting with the first one on or after `day`.
    static func everyTwoWeeks(weekday: Int, startingOnOrAfter day: CalendarDay, calendar: Calendar) -> RepeatRule {
        let weekday = Self.clampedWeekday(weekday)
        let ahead = (weekday - day.weekday(in: calendar) + 7) % 7
        return .everyTwoWeeks(weekday: weekday, anchor: day.adding(days: ahead, calendar: calendar))
    }

    var kind: RepeatKind {
        switch self {
        case .daily: .daily
        case .weekly: .weekly
        case .everyTwoWeeks: .everyTwoWeeks
        case .monthly: .monthly
        case .yearly: .yearly
        case .once: .once
        }
    }

    func isDue(on day: CalendarDay, calendar: Calendar) -> Bool {
        switch self {
        case .daily:
            return true
        case .weekly(let weekdays):
            return weekdays.contains(day.weekday(in: calendar))
        case .everyTwoWeeks(let weekday, let anchor):
            guard day.weekday(in: calendar) == weekday else { return false }
            let weeks = Int((Double(anchor.days(to: day, calendar: calendar)) / 7).rounded(.down))
            return weeks.isMultiple(of: 2)
        case .monthly(let monthDay):
            return day.day == min(monthDay, day.numberOfDaysInMonth(calendar: calendar))
        case .yearly(let month, let monthDay):
            guard day.month == month else { return false }
            return day.day == min(monthDay, day.numberOfDaysInMonth(calendar: calendar))
        case .once(let date):
            return day == date
        }
    }

    /// The first due day from `day` on, looking up to two years ahead.
    func nextDueDay(onOrAfter day: CalendarDay, calendar: Calendar) -> CalendarDay? {
        if case .once(let date) = self { return date >= day ? date : nil }
        for offset in 0..<(366 * 2) {
            let candidate = day.adding(days: offset, calendar: calendar)
            if isDue(on: candidate, calendar: calendar) { return candidate }
        }
        return nil
    }

    /// A one-off whose day has gone by.
    func isPast(before day: CalendarDay) -> Bool {
        if case .once(let date) = self { return date < day }
        return false
    }

    /// "Every day", "Every Friday", "Every other Friday", "Monthly on the 1st", "Every year, Nov 6",
    /// "Once · Fri, Nov 6".
    func label(calendar: Calendar, locale: Locale) -> String {
        switch self {
        case .daily:
            return String(localized: "Every day")
        case .weekly(let weekdays):
            return Self.weeklyLabel(weekdays, calendar: calendar, locale: locale)
        case .everyTwoWeeks(let weekday, _):
            return String(localized: "Every other \(Self.weekdayName(weekday, calendar: calendar, locale: locale))")
        case .monthly(let day):
            return String(localized: "Monthly on the \(Self.ordinal(day, locale: locale))")
        case .yearly(let month, let day):
            let date = CalendarDay(year: 2028, month: month, day: day).noon(in: calendar)
            return String(localized: "Every year, \(date.formatted(Self.monthDay(calendar: calendar, locale: locale)))")
        case .once(let day):
            return String(localized: "Once · \(Self.shortDate(day, calendar: calendar, locale: locale))")
        }
    }

    /// "Every Friday", "Every weekday", "Every weekend", "Every Mon, Wed, Fri", or "Every day" for all seven.
    private static func weeklyLabel(_ weekdays: Set<Int>, calendar: Calendar, locale: Locale) -> String {
        switch weekdays {
        case workingDays: return String(localized: "Every weekday")
        case weekendDays: return String(localized: "Every weekend")
        case Set(1...7): return String(localized: "Every day")
        default: break
        }
        if weekdays.count == 1, let weekday = weekdays.first {
            return String(localized: "Every \(weekdayName(weekday, calendar: calendar, locale: locale))")
        }
        var calendar = calendar
        calendar.locale = locale
        let names = weekOrder(weekdays, calendar: calendar).map { calendar.shortStandaloneWeekdaySymbols[$0 - 1] }
        return String(localized: "Every \(names.joined(separator: ", "))")
    }

    /// `weekdays` in the calendar's week order (Monday first in many places).
    static func weekOrder(_ weekdays: Set<Int>, calendar: Calendar) -> [Int] {
        (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }.filter(weekdays.contains)
    }

    /// "Fri, Nov 6", the design's short date.
    static func shortDate(_ day: CalendarDay, calendar: Calendar, locale: Locale) -> String {
        day.noon(in: calendar).formatted(monthDay(calendar: calendar, locale: locale).weekday(.abbreviated))
    }

    static func monthDay(calendar: Calendar, locale: Locale) -> Date.FormatStyle {
        var style = Date.FormatStyle(date: .omitted, time: .omitted, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
        style = style.month(.abbreviated).day()
        return style
    }

    static func weekdayName(_ weekday: Int, calendar: Calendar, locale: Locale) -> String {
        var calendar = calendar
        calendar.locale = locale
        return calendar.standaloneWeekdaySymbols[clampedWeekday(weekday) - 1]
    }

    static func ordinal(_ number: Int, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    static func clampedWeekday(_ weekday: Int) -> Int { min(max(weekday, 1), 7) }
}

/// The six repeat choices, as stored and as `NewCategory.dc.html`'s Repeat chips name them.
nonisolated enum RepeatKind: String, CaseIterable, Codable, Sendable {
    case daily, weekly, everyTwoWeeks, monthly, yearly, once

    var title: String {
        switch self {
        case .daily: String(localized: "Daily")
        case .weekly: String(localized: "Weekly")
        case .everyTwoWeeks: String(localized: "Every 2 weeks")
        case .monthly: String(localized: "Monthly")
        case .yearly: String(localized: "Yearly")
        case .once: String(localized: "On a date")
        }
    }
}
