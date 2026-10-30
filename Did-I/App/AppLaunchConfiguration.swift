import Foundation

/// Where the component gallery starts.
enum GalleryPage: String {
    case tiles, controls, calendar, agenda, category
}

/// How this launch sets up storage: on disk for real use, in memory and with fresh settings under tests.
struct AppLaunchConfiguration {
    /// Launched by a UI test with `-UITests` (Debug builds only).
    let isUITesting: Bool
    /// Hosting the unit tests.
    let isUnitTesting: Bool
    /// Launched with `-Gallery` to show the component gallery (Debug builds only).
    var showsGallery: Bool { galleryPage != nil }
    /// Launched with `-SeedSample` to add the design's sample checks to an empty store (Debug builds only).
    let seedsSampleData: Bool
    /// `-Open <screen>` opens a screen at launch, for screenshots (Debug builds only): addChecks, history,
    /// settings, actionButton, detail (the first check), logged.
    let debugOpen: String?
    /// `-Gallery` starts at the tiles; `-GalleryControls`, `-GalleryCalendar`, `-GalleryAgenda` and
    /// `-GalleryCategory` at those components.
    let galleryPage: GalleryPage?
    /// Launched with `-Appearance light|dark` to force a theme (Debug builds only).
    let forcedAppearance: Appearance?

    var usesInMemoryStore: Bool { isUITesting || isUnitTesting }

    init(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        #if DEBUG
        isUITesting = arguments.contains("-UITests")
        galleryPage = [GalleryPage.controls, .calendar, .agenda, .category]
            .first { arguments.contains("-Gallery" + $0.rawValue.capitalized) }
            ?? (arguments.contains("-Gallery") ? .tiles : nil)
        seedsSampleData = arguments.contains("-SeedSample")
        debugOpen = arguments.firstIndex(of: "-Open").flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
        forcedAppearance = arguments.firstIndex(of: "-Appearance")
            .flatMap { arguments.indices.contains($0 + 1) ? Appearance(rawValue: arguments[$0 + 1]) : nil }
        #else
        isUITesting = false
        galleryPage = nil
        seedsSampleData = false
        debugOpen = nil
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
