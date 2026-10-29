import CoreText
import Foundation

/// Registers the bundled Bricolage Grotesque and DM Sans for this process (the app or the widget extension).
nonisolated enum FontRegistration {
    private static let once: Void = {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    }()

    static func registerBundledFonts() {
        _ = once
    }
}
