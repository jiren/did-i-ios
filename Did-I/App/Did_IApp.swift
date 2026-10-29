import SwiftUI

@main
struct Did_IApp: App {
    private let configuration: AppLaunchConfiguration
    @State private var settings: AppSettings

    init() {
        FontRegistration.registerBundledFonts()
        let configuration = AppLaunchConfiguration()
        self.configuration = configuration
        let settings = AppSettings(defaults: configuration.makeDefaults())
        if let forced = configuration.forcedAppearance { settings.appearance = forced }
        _settings = State(initialValue: settings)
    }

    var body: some Scene {
        WindowGroup {
            content
                .environment(settings)
                .preferredColorScheme(settings.appearance.colorScheme)
                .tint(Color.tileViolet)
        }
    }

    @ViewBuilder
    private var content: some View {
        #if DEBUG
        if configuration.showsGallery {
            ComponentGallery(startsAtControls: configuration.galleryStartsAtControls)
        } else {
            RootView()
        }
        #else
        RootView()
        #endif
    }
}
