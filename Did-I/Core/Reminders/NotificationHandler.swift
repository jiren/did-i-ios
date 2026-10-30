import Foundation
import UserNotifications

/// Handles taps on reminders and nudges: Log it logs without opening the app; a tap opens the category on Today
/// (category reminders) or the check (nudges).
final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    private let store: SwiftDataStore
    private let changes: StoreChangeHub
    private let timeSource: any TimeSource

    init(store: SwiftDataStore, changes: StoreChangeHub, timeSource: any TimeSource) {
        self.store = store
        self.changes = changes
        self.timeSource = timeSource
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        let checkID = (info[ReminderScheduler.checkIDKey] as? String).flatMap(UUID.init(uuidString:))
        let categoryID = (info[ReminderScheduler.categoryIDKey] as? String).flatMap(UUID.init(uuidString:))
        if response.actionIdentifier == ReminderScheduler.logActionIdentifier, let checkID {
            _ = try? store.log(checkID, source: .notification, at: timeSource.now, photoFileName: nil)
            changes.didChange()
        } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            if let categoryID {
                IntentServices.shared.openCategory?(categoryID)
            } else if let checkID {
                IntentServices.shared.openCheck?(checkID)
            }
        }
    }
}
