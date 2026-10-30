import Foundation

/// The tile colours, cycled by a check's position in the whole list (`Main.dc.html`'s palette); also a
/// category's colour.
nonisolated enum TileSwatch: Int, CaseIterable, Sendable {
    case violet, sun, coral, mint, sky, pink

    static func at(position: Int) -> TileSwatch {
        allCases[((position % allCases.count) + allCases.count) % allCases.count]
    }

    /// The stored name ("violet"), so the order of the cases can change.
    var key: String {
        switch self {
        case .violet: "violet"
        case .sun: "sun"
        case .coral: "coral"
        case .mint: "mint"
        case .sky: "sky"
        case .pink: "pink"
        }
    }

    init?(key: String) {
        guard let swatch = Self.allCases.first(where: { $0.key == key }) else { return nil }
        self = swatch
    }

    /// The colour's name for VoiceOver (`NewCategory.dc.html`'s swatches).
    var title: String {
        switch self {
        case .violet: String(localized: "Violet")
        case .sun: String(localized: "Sun")
        case .coral: String(localized: "Coral")
        case .mint: String(localized: "Mint")
        case .sky: String(localized: "Sky")
        case .pink: String(localized: "Pink")
        }
    }
}
