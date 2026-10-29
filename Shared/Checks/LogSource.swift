import Foundation

/// Where a log came from; History shows it.
nonisolated enum LogSource: String, CaseIterable, Codable, Sendable {
    case app, lockScreenWidget, homeScreenWidget, actionButton, control, siri, shortcut, notification

    var label: String {
        switch self {
        case .app: String(localized: "In the app")
        case .lockScreenWidget: String(localized: "Lock Screen widget")
        case .homeScreenWidget: String(localized: "Home Screen widget")
        case .actionButton: String(localized: "Action Button")
        case .control: String(localized: "Action Button or Control Center")
        case .siri: String(localized: "Siri")
        case .shortcut: String(localized: "Siri or Shortcuts")
        case .notification: String(localized: "Notification")
        }
    }

    /// "Action Button · photo" when the log has one.
    func label(hasPhoto: Bool) -> String {
        hasPhoto ? String(localized: "\(label) · photo") : label
    }
}
