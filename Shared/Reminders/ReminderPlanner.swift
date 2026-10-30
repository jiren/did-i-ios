import Foundation

/// A local notification to schedule.
nonisolated struct PlannedReminder: Hashable, Sendable {
    let identifier: String
    /// The task Log it logs; nil when there's more than one left (a tap opens the category instead).
    let checkID: UUID?
    /// The category a tap opens Today on.
    var categoryID: UUID?
    let fireDate: Date
    let title: String
    let body: String
}

/// Which category reminders to schedule (`Plan.md`, category reminders): one per category at its "Remind me at"
/// time on each day it's due, today's only while a task in it isn't logged, for today and tomorrow, nearest
/// first, within iOS's limit on pending notifications.
nonisolated enum ReminderPlanner {
    static let identifierPrefix = "reminder-"
    /// iOS keeps at most 64 pending requests; leave room for nudges.
    static let budget = 60

    static func plan(
        checks: [CheckRecord], categories: [CategoryRecord], latestLogs: [UUID: LogRecord], now: Date, boundary: DayBoundary
    ) -> [PlannedReminder] {
        let calendar = boundary.calendar
        var planned: [PlannedReminder] = []
        for category in categories {
            guard let minutes = category.reminderMinutes else { continue }
            let tasks = checks.filter { $0.categoryID == category.id }
            guard !tasks.isEmpty else { continue }
            for dayOffset in 0...1 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)),
                      category.rule.isDue(on: CalendarDay(day, calendar: calendar), calendar: calendar),
                      let fire = calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day),
                      fire > now else { continue }
                let left = tasks.filter { task in
                    guard let latest = latestLogs[task.id]?.date else { return true }
                    return !boundary.isInSameDay(latest, as: fire)
                }
                guard !left.isEmpty else { continue }
                planned.append(PlannedReminder(
                    identifier: identifier(categoryID: category.id, fireDate: fire, calendar: calendar),
                    checkID: left.count == 1 ? left[0].id : nil,
                    categoryID: category.id,
                    fireDate: fire,
                    title: category.name,
                    body: body(left: left.map(\.name))
                ))
            }
        }
        return Array(planned.sorted { $0.fireDate < $1.fireDate }.prefix(budget))
    }

    /// "1 left: Bins out" or "2 left: Bins out, Recycling out".
    static func body(left names: [String]) -> String {
        String(localized: "\(names.count) left: \(names.joined(separator: ", "))")
    }

    static func identifier(categoryID: UUID, fireDate: Date, calendar: Calendar) -> String {
        let day = calendar.dateComponents([.year, .month, .day], from: fireDate)
        return "\(identifierPrefix)\(categoryID.uuidString)-\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
    }
}

/// What to tell someone leaving home, per check with the nudge on and due today (`Detail.dc.html`,
/// `LockScreen.dc.html`).
nonisolated enum LeaveHomeNudge {
    static let identifierPrefix = "nudge-"

    static func notifications(
        checks: [CheckRecord], dueIDs: Set<UUID>, latestLogs: [UUID: LogRecord], now: Date, time: RelativeTime, reassures: Bool
    ) -> [PlannedReminder] {
        checks.filter { $0.nudgesOnLeavingHome && dueIDs.contains($0.id) }.compactMap { check in
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
