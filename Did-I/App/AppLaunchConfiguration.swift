import Foundation

/// How this launch sets up storage: on disk for real use, in memory and with fresh settings under tests.
struct AppLaunchConfiguration {
    /// Launched by a UI test with `-UITests` (Debug builds only).
    let isUITesting: Bool
    /// Hosting the unit tests.
    let isUnitTesting: Bool
    /// Launched with `-Gallery` to show the component gallery (Debug builds only).
    let showsGallery: Bool
    /// Launched with `-SeedSample` to add the design's sample checks to an empty store (Debug builds only).
    let seedsSampleData: Bool
    /// `-GalleryControls` starts the gallery at its controls.
    let galleryStartsAtControls: Bool
    /// Launched with `-Appearance light|dark` to force a theme (Debug builds only).
    let forcedAppearance: Appearance?

    var usesInMemoryStore: Bool { isUITesting || isUnitTesting }

    init(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        #if DEBUG
        isUITesting = arguments.contains("-UITests")
        showsGallery = arguments.contains("-Gallery") || arguments.contains("-GalleryControls")
        galleryStartsAtControls = arguments.contains("-GalleryControls")
        seedsSampleData = arguments.contains("-SeedSample")
        forcedAppearance = arguments.firstIndex(of: "-Appearance")
            .flatMap { arguments.indices.contains($0 + 1) ? Appearance(rawValue: arguments[$0 + 1]) : nil }
        #else
        isUITesting = false
        showsGallery = false
        galleryStartsAtControls = false
        seedsSampleData = false
        forcedAppearance = nil
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
