import Foundation

/// A local notification to schedule.
nonisolated struct PlannedReminder: Hashable, Sendable {
    let identifier: String
    let checkID: UUID
    let fireDate: Date
    let title: String
    let body: String
}

/// Which "if not logged" reminders to schedule: today's (when still ahead and not logged) and tomorrow's,
/// nearest first, within iOS's limit on pending notifications. Each check reminds at its category's time on the
/// days its category is due (phase 17 turns these into one reminder per category).
nonisolated enum ReminderPlanner {
    static let identifierPrefix = "reminder-"
    /// iOS keeps at most 64 pending requests; leave room for nudges.
    static let budget = 60

    static func plan(
        checks: [CheckRecord], categories: [CategoryRecord], latestLogs: [UUID: LogRecord], now: Date, boundary: DayBoundary
    ) -> [PlannedReminder] {
        let calendar = boundary.calendar
        let categories = Dictionary(categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var planned: [PlannedReminder] = []
        for check in checks {
            guard let category = categories[check.categoryID], let minutes = category.reminderMinutes else { continue }
            for dayOffset in 0...1 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)),
                      category.rule.isDue(on: CalendarDay(day, calendar: calendar), calendar: calendar),
                      let fire = calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day),
                      fire > now else { continue }
                if let latest = latestLogs[check.id]?.date, boundary.isInSameDay(latest, as: fire) { continue }
                planned.append(PlannedReminder(
                    identifier: identifier(checkID: check.id, fireDate: fire, calendar: calendar),
                    checkID: check.id,
                    fireDate: fire,
                    title: check.name,
                    body: String(localized: "Not logged yet today. If you did it, tap Log it.")
                ))
            }
        }
        return Array(planned.sorted { $0.fireDate < $1.fireDate }.prefix(budget))
    }

    static func identifier(checkID: UUID, fireDate: Date, calendar: Calendar) -> String {
        let day = calendar.dateComponents([.year, .month, .day], from: fireDate)
        return "\(identifierPrefix)\(checkID.uuidString)-\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
    }
}

/// What to tell someone leaving home, per check with the nudge on (`Detail.dc.html`, `LockScreen.dc.html`).
nonisolated enum LeaveHomeNudge {
    static let identifierPrefix = "nudge-"

    static func notifications(
        checks: [CheckRecord], latestLogs: [UUID: LogRecord], now: Date, time: RelativeTime, reassures: Bool
    ) -> [PlannedReminder] {
        checks.filter(\.nudgesOnLeavingHome).compactMap { check in
            let identifier = identifierPrefix + check.id.uuidString
            if let latest = latestLogs[check.id]?.date, time.boundary.isInSameDay(latest, as: now) {
                guard reassures else { return nil }
                return PlannedReminder(
                    identifier: identifier, checkID: check.id, fireDate: now,
                    title: String(localized: "\(check.name) — \(time.clockTime(latest))"),
                    body: String(localized: "You already checked. You’re good.")
                )
            }
            return PlannedReminder(
                identifier: identifier, checkID: check.id, fireDate: now,
                title: String(localized: "Leaving home? \(check.name)"),
                body: String(localized: "Not logged yet today. Check it, then tap Log it.")
            )
        }
    }
}
