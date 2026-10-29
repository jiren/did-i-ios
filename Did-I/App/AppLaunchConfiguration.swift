import Foundation

/// How this launch sets up storage: on disk for real use, in memory and with fresh settings under tests.
struct AppLaunchConfiguration {
    /// Launched by a UI test with `-UITests` (Debug builds only).
    let isUITesting: Bool
    /// Hosting the unit tests.
    let isUnitTesting: Bool

    var usesInMemoryStore: Bool { isUITesting || isUnitTesting }

    init(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        #if DEBUG
        isUITesting = arguments.contains("-UITests")
        #else
        isUITesting = false
        #endif
        isUnitTesting = environment["XCTestConfigurationFilePath"] != nil
    }

    /// The group suite for real use; an emptied suite of its own under tests.
    func makeDefaults() -> UserDefaults {
        guard usesInMemoryStore else { return AppGroup.defaults }
        let name = "com.elo.Did-I.tests"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
