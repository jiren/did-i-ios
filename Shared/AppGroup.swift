import Foundation

/// The App Group the app and the widget extension share: one store, one settings suite, one photo folder.
nonisolated enum AppGroup {
    static let identifier = "group.com.elo.Did-I"

    /// The group's container, or Application Support when the group isn't available (an unsigned test host).
    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
            ?? URL.applicationSupportDirectory
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
