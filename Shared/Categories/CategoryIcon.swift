import Foundation

/// A category's icon: one of the 12 drawn in `NewCategory.dc.html`, or any symbol from the icon library.
/// Stored as the drawn icon's name ("bin") or "sf:<symbol>".
nonisolated struct CategoryIcon: Hashable, Sendable {
    let rawValue: String
    let symbolName: String

    private init(rawValue: String, symbolName: String) {
        self.rawValue = rawValue
        self.symbolName = symbolName
    }

    static let suitcase = CategoryIcon(rawValue: "suitcase", symbolName: "suitcase.fill")
    static let sun = CategoryIcon(rawValue: "sun", symbolName: "sun.max.fill")
    static let home = CategoryIcon(rawValue: "home", symbolName: "house.fill")
    static let bin = CategoryIcon(rawValue: "bin", symbolName: "trash.fill")
    static let lock = CategoryIcon(rawValue: "lock", symbolName: "lock.fill")
    static let pill = CategoryIcon(rawValue: "pill", symbolName: "pills.fill")
    static let flame = CategoryIcon(rawValue: "flame", symbolName: "flame.fill")
    static let plug = CategoryIcon(rawValue: "plug", symbolName: "powerplug.fill")
    static let car = CategoryIcon(rawValue: "car", symbolName: "car.fill")
    static let key = CategoryIcon(rawValue: "key", symbolName: "key.fill")
    static let heart = CategoryIcon(rawValue: "heart", symbolName: "heart.fill")
    static let globe = CategoryIcon(rawValue: "globe", symbolName: "globe")

    /// The 12 drawn icons, in the design's order.
    static let featured: [CategoryIcon] = [.suitcase, .sun, .home, .bin, .lock, .pill, .flame, .plug, .car, .key, .heart, .globe]

    private static let symbolPrefix = "sf:"

    /// From a stored value: a drawn icon's name, or "sf:<symbol>".
    init?(rawValue: String) {
        if let icon = Self.featured.first(where: { $0.rawValue == rawValue }) {
            self = icon
        } else if rawValue.hasPrefix(Self.symbolPrefix), rawValue.count > Self.symbolPrefix.count {
            self.init(symbol: String(rawValue.dropFirst(Self.symbolPrefix.count)))
        } else {
            return nil
        }
    }

    /// Any SF Symbol; a drawn icon's symbol gives that icon.
    init(symbol: String) {
        if let icon = Self.featured.first(where: { $0.symbolName == symbol }) {
            self = icon
        } else {
            self.init(rawValue: Self.symbolPrefix + symbol, symbolName: symbol)
        }
    }

    var isFeatured: Bool { !rawValue.hasPrefix(Self.symbolPrefix) }

    /// The VoiceOver name, "Suitcase" in "Suitcase icon".
    var title: String {
        switch rawValue {
        case "suitcase": String(localized: "Suitcase")
        case "sun": String(localized: "Sun")
        case "home": String(localized: "Home")
        case "bin": String(localized: "Bin")
        case "lock": String(localized: "Lock")
        case "pill": String(localized: "Pill")
        case "flame": String(localized: "Flame")
        case "plug": String(localized: "Plug")
        case "car": String(localized: "Car")
        case "key": String(localized: "Key")
        case "heart": String(localized: "Heart")
        case "globe": String(localized: "Globe")
        default: IconLibrary.title(for: symbolName)
        }
    }
}
