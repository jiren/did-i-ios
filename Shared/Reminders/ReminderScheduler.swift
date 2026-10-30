import Foundation
import UserNotifications

/// The parts of `UNUserNotificationCenter` reminders use, so tests can stand in.
protocol NotificationScheduling: AnyObject {
    func pendingIdentifiers() async -> [String]
    func add(_ reminder: PlannedReminder, immediately: Bool) async
    func removePending(_ identifiers: [String])
}

/// Keeps the pending category reminders matching the categories, their tasks and today's logs.
final class ReminderScheduler {
    /// A reminder or nudge for one task, with Log it.
    static let categoryIdentifier = "CHECK_REMINDER"
    /// A category reminder with more than one task left: a tap opens Today on the category.
    static let groupCategoryIdentifier = "CATEGORY_REMINDER"
    static let logActionIdentifier = "LOG_IT"
    static let checkIDKey = "checkID"
    static let categoryIDKey = "categoryID"

    private let center: any NotificationScheduling

    init(center: any NotificationScheduling = SystemNotificationCenter()) {
        self.center = center
    }

    func reschedule(
        checks: [CheckRecord], categories: [CategoryRecord], latestLogs: [UUID: LogRecord], now: Date, boundary: DayBoundary
    ) async {
        let planned = ReminderPlanner.plan(checks: checks, categories: categories, latestLogs: latestLogs, now: now, boundary: boundary)
        let stale = await center.pendingIdentifiers().filter { $0.hasPrefix(ReminderPlanner.identifierPrefix) }
        center.removePending(stale)
        for reminder in planned {
            await center.add(reminder, immediately: false)
        }
    }

    /// Reads the store and reschedules; used after any write in either process.
    func reschedule(store: SwiftDataStore, settings: AppSettings, now: Date) async {
        guard let checks = try? store.checks(), let categories = try? store.categories(),
              let latest = try? store.latestLogs() else { return }
        await reschedule(checks: checks, categories: categories, latestLogs: latest, now: now, boundary: settings.dayBoundary)
    }

    func post(_ reminders: [PlannedReminder]) async {
        for reminder in reminders {
            await center.add(reminder, immediately: true)
        }
    }

    /// The Log it action, registered once at launch.
    static func registerCategory() {
        let log = UNNotificationAction(identifier: logActionIdentifier, title: String(localized: "Log it"), options: [])
        let single = UNNotificationCategory(identifier: categoryIdentifier, actions: [log], intentIdentifiers: [])
        let group = UNNotificationCategory(identifier: groupCategoryIdentifier, actions: [], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([single, group])
    }
}

final class SystemNotificationCenter: NotificationScheduling {
    private var center: UNUserNotificationCenter { .current() }

    func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }

    func add(_ reminder: PlannedReminder, immediately: Bool) async {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        content.categoryIdentifier = reminder.checkID == nil
            ? ReminderScheduler.groupCategoryIdentifier
            : ReminderScheduler.categoryIdentifier
        var info: [String: String] = [:]
        info[ReminderScheduler.checkIDKey] = reminder.checkID?.uuidString
        info[ReminderScheduler.categoryIDKey] = reminder.categoryID?.uuidString
        content.userInfo = info
        let trigger: UNNotificationTrigger? = immediately ? nil : UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate),
            repeats: false
        )
        try? await center.add(UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger))
    }

    func removePending(_ identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
