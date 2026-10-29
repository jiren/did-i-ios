import UserNotifications

enum NotificationPermission {
    enum Status: Equatable {
        case allowed, denied, notAsked
    }

    static func status() async -> Status {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: .allowed
        case .denied: .denied
        default: .notAsked
        }
    }

    /// Asks once; afterwards reports the answer.
    @discardableResult
    static func request() async -> Status {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        return await status()
    }
}
