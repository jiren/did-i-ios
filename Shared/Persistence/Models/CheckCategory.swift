import Foundation
import SwiftData

extension SchemaV3 {
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
                }
            }
            set {
                repeatKindRaw = newValue.kind.rawValue
                repeatWeekday = nil
                repeatWeekdayMask = nil
                repeatYear = nil
                repeatMonth = nil
                repeatDay = nil
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
                }
            }
        }

        private static func weekdays(fromMask mask: Int) -> Set<Int> {
            Set((1...7).filter { mask & (1 << ($0 - 1)) != 0 })
        }
    }
}
