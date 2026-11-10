import Foundation
import SwiftData

extension SchemaV4 {
    /// A group of checks with its own icon, colour, schedule and reminder (`NewCategory.dc.html`).
    @Model
    final class CheckCategory {
        @Attribute(.unique) var id: UUID
        var name: String
        /// A `CategoryIcon` raw value: a drawn icon's name or "sf:<symbol>".
        var iconRaw: String
        /// A `CategoryColour` key: a swatch's name or "#RRGGBB".
        var colourRaw: String
        /// A `RepeatKind` raw value; the fields after it hold its details.
        var repeatKindRaw: String
        /// 1 (Sunday) to 7, for every-two-weeks rules (and weekly rules saved before phase 22).
        var repeatWeekday: Int?
        /// A weekly rule's days, one bit per weekday (bit 0 is Sunday). Nil for rules saved before phase 22, which
        /// use `repeatWeekday`.
        var repeatWeekdayMask: Int?
        /// The year for a one-off date or an every-two-weeks anchor.
        var repeatYear: Int?
        var repeatMonth: Int?
        /// The day of the month for monthly, yearly and one-off rules and the anchor.
        var repeatDay: Int?
        /// Minutes after midnight for the "only if something's not logged" reminder, or nil for none.
        var reminderMinutes: Int?
        /// A `PartOfDay` raw value; nil (categories saved before phase 26) reads Anytime.
        var partOfDayRaw: String?
        /// A custom rule's unit, a `CustomRepeat.Unit` raw value. A custom rule also uses `repeatWeekdayMask` (its
        /// weekdays), `repeatMonth` (a yearly month), and `repeatDay` or `repeatWeekday` with `repeatOrdinal`.
        var repeatFrequencyRaw: String?
        /// A custom rule's "every n".
        var repeatInterval: Int?
        /// 1 to 4, or -1 for the last: "the first Monday" with `repeatWeekday`. Nil means on `repeatDay`.
        var repeatOrdinal: Int?
        /// The calendar's first weekday when a custom weekly rule was saved.
        var repeatWeekStart: Int?
        /// A custom rule's start.
        var repeatStartYear: Int?
        var repeatStartMonth: Int?
        var repeatStartDay: Int?
        /// A custom rule's last day, when it ends on a date.
        var repeatEndYear: Int?
        var repeatEndMonth: Int?
        var repeatEndDay: Int?
        /// How many times a custom rule happens, when it ends after a count.
        var repeatEndCount: Int?
        /// Position of the filter chips and sections, ascending.
        var order: Int
        /// Daily: always there, can't be deleted or rescheduled.
        var isDefault: Bool
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \Check.category)
        var checks: [Check] = []

        init(id: UUID = UUID(), name: String, icon: CategoryIcon, colour: CategoryColour, rule: RepeatRule, order: Int, isDefault: Bool = false, now: Date) {
            self.id = id
            self.name = name
            self.iconRaw = icon.rawValue
            self.colourRaw = colour.key
            self.repeatKindRaw = RepeatKind.daily.rawValue
            self.order = order
            self.isDefault = isDefault
            self.createdAt = now
            self.updatedAt = now
            self.rule = rule
        }

        var rule: RepeatRule {
            get {
                let weekday = RepeatRule.clampedWeekday(repeatWeekday ?? 1)
                let day = CalendarDay(year: repeatYear ?? 2026, month: repeatMonth ?? 1, day: repeatDay ?? 1)
                switch RepeatKind(rawValue: repeatKindRaw) ?? .daily {
                case .daily: return .daily
                case .weekly:
                    let days = repeatWeekdayMask.map(Self.weekdays(fromMask:)) ?? [weekday]
                    return .weekly(weekdays: days.isEmpty ? [weekday] : days)
                case .everyTwoWeeks: return .everyTwoWeeks(weekday: weekday, anchor: day)
                case .monthly: return .monthly(day: day.day)
                case .yearly: return .yearly(month: day.month, day: day.day)
                case .once: return .once(day)
                case .custom: return .custom(customRule)
                }
            }
            set {
                repeatKindRaw = newValue.kind.rawValue
                repeatWeekday = nil
                repeatWeekdayMask = nil
                repeatYear = nil
                repeatMonth = nil
                repeatDay = nil
                repeatFrequencyRaw = nil
                repeatInterval = nil
                repeatOrdinal = nil
                repeatWeekStart = nil
                (repeatStartYear, repeatStartMonth, repeatStartDay) = (nil, nil, nil)
                (repeatEndYear, repeatEndMonth, repeatEndDay) = (nil, nil, nil)
                repeatEndCount = nil
                switch newValue {
                case .daily:
                    break
                case .weekly(let weekdays):
                    repeatWeekdayMask = weekdays.reduce(0) { $0 | (1 << ($1 - 1)) }
                    repeatWeekday = weekdays.min()
                case .everyTwoWeeks(let weekday, let anchor):
                    repeatWeekday = weekday
                    (repeatYear, repeatMonth, repeatDay) = (anchor.year, anchor.month, anchor.day)
                case .monthly(let day):
                    repeatDay = day
                case .yearly(let month, let day):
                    (repeatMonth, repeatDay) = (month, day)
                case .once(let day):
                    (repeatYear, repeatMonth, repeatDay) = (day.year, day.month, day.day)
                case .custom(let custom):
                    store(custom.normalized())
                }
            }
        }

        var partOfDay: PartOfDay {
            get { partOfDayRaw.flatMap(PartOfDay.init(rawValue:)) ?? .anytime }
            set { partOfDayRaw = newValue == .anytime ? nil : newValue.rawValue }
        }

        /// The stored custom rule; missing parts fall back rather than trap.
        private var customRule: CustomRepeat {
            let start = CalendarDay(year: repeatStartYear ?? 2026, month: repeatStartMonth ?? 1, day: repeatStartDay ?? 1)
            let position: CustomRepeat.MonthPosition = if let ordinal = repeatOrdinal.flatMap(CustomRepeat.WeekOrdinal.init(rawValue:)) {
                .weekday(RepeatRule.clampedWeekday(repeatWeekday ?? 1), ordinal)
            } else {
                .day(repeatDay ?? start.day)
            }
            let frequency: CustomRepeat.Frequency = switch CustomRepeat.Unit(rawValue: repeatFrequencyRaw ?? "") ?? .days {
            case .days: .daily
            case .weeks: .weekly(weekdays: repeatWeekdayMask.map(Self.weekdays(fromMask:)) ?? [])
            case .months: .monthly(position)
            case .years: .yearly(month: repeatMonth ?? start.month, position)
            }
            let end: CustomRepeat.End = if let count = repeatEndCount {
                .after(count)
            } else if let year = repeatEndYear, let month = repeatEndMonth, let day = repeatEndDay {
                .on(CalendarDay(year: year, month: month, day: day))
            } else {
                .never
            }
            return CustomRepeat(
                frequency: frequency, interval: repeatInterval ?? 1, start: start, end: end, weekStart: repeatWeekStart ?? 1
            ).normalized()
        }

        private func store(_ custom: CustomRepeat) {
            repeatFrequencyRaw = custom.unit.rawValue
            repeatInterval = custom.interval
            repeatWeekStart = custom.weekStart
            (repeatStartYear, repeatStartMonth, repeatStartDay) = (custom.start.year, custom.start.month, custom.start.day)
            let position: CustomRepeat.MonthPosition?
            switch custom.frequency {
            case .daily:
                position = nil
            case .weekly(let weekdays):
                repeatWeekdayMask = weekdays.reduce(0) { $0 | (1 << ($1 - 1)) }
                position = nil
            case .monthly(let monthPosition):
                position = monthPosition
            case .yearly(let month, let monthPosition):
                repeatMonth = month
                position = monthPosition
            }
            switch position {
            case .day(let day): repeatDay = day
            case .weekday(let weekday, let ordinal): (repeatWeekday, repeatOrdinal) = (weekday, ordinal.rawValue)
            case nil: break
            }
            switch custom.end {
            case .never: break
            case .on(let last): (repeatEndYear, repeatEndMonth, repeatEndDay) = (last.year, last.month, last.day)
            case .after(let count): repeatEndCount = count
            }
        }

        private static func weekdays(fromMask mask: Int) -> Set<Int> {
            Set((1...7).filter { mask & (1 << ($0 - 1)) != 0 })
        }
    }
}
