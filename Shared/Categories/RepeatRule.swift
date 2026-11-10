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
    /// Calendar-style: every n days, weeks, months or years, with a start and an end (Phase 26).
    case custom(CustomRepeat)

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
        case .custom: .custom
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
        case .custom(let custom):
            return custom.isDue(on: day, calendar: calendar)
        }
    }

    /// The first due day from `day` on: worked out for a one-off or a custom rule, else looking up to two years
    /// ahead (every other kind recurs within a year).
    func nextDueDay(onOrAfter day: CalendarDay, calendar: Calendar) -> CalendarDay? {
        if case .once(let date) = self { return date >= day ? date : nil }
        if case .custom(let custom) = self { return custom.nextDueDay(onOrAfter: day, calendar: calendar) }
        for offset in 0..<(366 * 2) {
            let candidate = day.adding(days: offset, calendar: calendar)
            if isDue(on: candidate, calendar: calendar) { return candidate }
        }
        return nil
    }

    /// A one-off whose day has gone by, or a custom rule that has ended.
    func isPast(before day: CalendarDay, calendar: Calendar) -> Bool {
        switch self {
        case .once(let date): date < day
        case .custom(let custom): custom.hasEnded(before: day, calendar: calendar)
        default: false
        }
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
        case .custom(let custom):
            return Self.customLabel(custom, calendar: calendar, locale: locale)
        }
    }

    // MARK: - Custom labels

    /// "Every 3 days", "Every other week on Mon, Wed", "Monthly on the first Monday", "Every 2 years, Nov 6", then
    /// " · until Dec 31" or " · 5 times".
    private static func customLabel(_ rule: CustomRepeat, calendar: Calendar, locale: Locale) -> String {
        let base = customBase(rule, calendar: calendar, locale: locale)
        switch rule.end {
        case .never:
            return base
        case .on(let last):
            var style = monthDay(calendar: calendar, locale: locale)
            if last.year != rule.start.year { style = style.year() }
            return String(localized: "\(base) · until \(last.noon(in: calendar).formatted(style))")
        case .after(let count):
            return count == 1 ? String(localized: "\(base) · 1 time") : String(localized: "\(base) · \(count) times")
        }
    }

    private static func customBase(_ rule: CustomRepeat, calendar: Calendar, locale: Locale) -> String {
        let n = rule.interval
        switch rule.frequency {
        case .daily:
            switch n {
            case 1: return String(localized: "Every day")
            case 2: return String(localized: "Every other day")
            default: return String(localized: "Every \(n) days")
            }
        case .weekly(let weekdays):
            if n == 1 { return weeklyLabel(weekdays, calendar: calendar, locale: locale) }
            if n == 2, weekdays.count == 1, let weekday = weekdays.first {
                return String(localized: "Every other \(weekdayName(weekday, calendar: calendar, locale: locale))")
            }
            let days = weekdayList(weekdays, calendar: calendar, locale: locale)
            return n == 2
                ? String(localized: "Every other week on \(days)")
                : String(localized: "Every \(n) weeks on \(days)")
        case .monthly(let position):
            if n == 1, case .day(let day) = position {
                return String(localized: "Monthly on the \(ordinal(day, locale: locale))")
            }
            let on = positionPhrase(position, calendar: calendar, locale: locale)
            switch n {
            case 1: return String(localized: "Monthly on \(on)")
            case 2: return String(localized: "Every other month on \(on)")
            default: return String(localized: "Every \(n) months on \(on)")
            }
        case .yearly(let month, let position):
            if case .day(let day) = position {
                let date = CalendarDay(year: 2028, month: month, day: day).noon(in: calendar)
                    .formatted(monthDay(calendar: calendar, locale: locale))
                switch n {
                case 1: return String(localized: "Every year, \(date)")
                case 2: return String(localized: "Every other year, \(date)")
                default: return String(localized: "Every \(n) years, \(date)")
                }
            }
            let on = positionPhrase(position, calendar: calendar, locale: locale)
            let monthName = self.monthName(month, calendar: calendar, locale: locale)
            switch n {
            case 1: return String(localized: "Every year on \(on) of \(monthName)")
            case 2: return String(localized: "Every other year on \(on) of \(monthName)")
            default: return String(localized: "Every \(n) years on \(on) of \(monthName)")
            }
        }
    }

    /// "Friday" for one day, else "Mon, Wed" in the calendar's week order.
    private static func weekdayList(_ weekdays: Set<Int>, calendar: Calendar, locale: Locale) -> String {
        if weekdays.count == 1, let weekday = weekdays.first { return weekdayName(weekday, calendar: calendar, locale: locale) }
        var calendar = calendar
        calendar.locale = locale
        return weekOrder(weekdays, calendar: calendar).map { calendar.shortStandaloneWeekdaySymbols[$0 - 1] }.joined(separator: ", ")
    }

    /// "the 15th" or "the first Monday".
    static func positionPhrase(_ position: CustomRepeat.MonthPosition, calendar: Calendar, locale: Locale) -> String {
        switch position {
        case .day(let day):
            return String(localized: "the \(ordinal(day, locale: locale))", comment: "A day of the month: “the 15th”.")
        case .weekday(let weekday, let ordinal):
            let name = weekdayName(weekday, calendar: calendar, locale: locale)
            switch ordinal {
            case .first: return String(localized: "the first \(name)", comment: "“the first Monday” of a month.")
            case .second: return String(localized: "the second \(name)", comment: "“the second Monday” of a month.")
            case .third: return String(localized: "the third \(name)", comment: "“the third Monday” of a month.")
            case .fourth: return String(localized: "the fourth \(name)", comment: "“the fourth Monday” of a month.")
            case .last: return String(localized: "the last \(name)", comment: "“the last Monday” of a month.")
            }
        }
    }

    static func monthName(_ month: Int, calendar: Calendar, locale: Locale) -> String {
        var calendar = calendar
        calendar.locale = locale
        let symbols = calendar.standaloneMonthSymbols
        return symbols[min(max(month, 1), symbols.count) - 1]
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

/// The repeat choices, as stored and as `NewCategory.dc.html`'s Repeat chips name them, then Custom (Phase 26).
nonisolated enum RepeatKind: String, CaseIterable, Codable, Sendable {
    case daily, weekly, everyTwoWeeks, monthly, yearly, once, custom

    var title: String {
        switch self {
        case .daily: String(localized: "Daily")
        case .weekly: String(localized: "Weekly")
        case .everyTwoWeeks: String(localized: "Every 2 weeks")
        case .monthly: String(localized: "Monthly")
        case .yearly: String(localized: "Yearly")
        case .once: String(localized: "On a date")
        case .custom: String(localized: "Custom")
        }
    }
}
