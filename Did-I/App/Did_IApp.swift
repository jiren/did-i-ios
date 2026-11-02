import SwiftUI

@main
struct Did_IApp: App {
    private let configuration: AppLaunchConfiguration
    @State private var settings: AppSettings
    @State private var launch: Result<AppEnvironment, LaunchError>

    init() {
        FontRegistration.registerBundledFonts()
        let configuration = AppLaunchConfiguration()
        DidITips.configure(forTesting: configuration.usesInMemoryStore)
        self.configuration = configuration
        let settings = AppSettings(defaults: configuration.makeDefaults())
        if let forced = configuration.forcedAppearance { settings.appearance = forced }
        _settings = State(initialValue: settings)
        _launch = State(initialValue: Self.makeEnvironment(configuration: configuration, settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            content
                .environment(settings)
                .preferredColorScheme(settings.appearance.colorScheme)
                .tint(Color.tileViolet)
        }
        .backgroundTask(.appRefresh(BackgroundRefresh.identifier)) {
            await refreshInBackground()
        }
    }

    /// Keeps tomorrow's reminders booked even if the app isn't opened.
    private func refreshInBackground() async {
        guard case .success(let environment) = launch else { return }
        environment.changes.refreshFromDisk()
        environment.rescheduleReminders()
    }

    @ViewBuilder
    private var content: some View {
        switch launch {
        case .success(let environment):
            #if DEBUG
            if let page = configuration.galleryPage {
                ComponentGallery(page: page)
            } else {
                RootView(environment: environment)
            }
            #else
            RootView(environment: environment)
            #endif
        case .failure(let error):
            LaunchFailureView(message: error.message)
        }
    }

    private static func makeEnvironment(
        configuration: AppLaunchConfiguration, settings: AppSettings
    ) -> Result<AppEnvironment, LaunchError> {
        switch AppEnvironment.makeContainer(for: configuration) {
        case .success(let container):
            let environment = AppEnvironment(configuration: configuration, settings: settings, container: container)
            #if DEBUG
            if configuration.seedsSampleData {
                SampleData.seed(into: environment.store, now: environment.timeSource.now)
            }
            if configuration.seedsStatsData {
                SampleData.seedStats(into: environment.store, now: environment.timeSource.now)
            }
            #endif
            return .success(environment)
        case .failure(let error):
            return .failure(LaunchError(message: error.localizedDescription))
        }
    }
}

struct LaunchError: Error {
    let message: String
}
