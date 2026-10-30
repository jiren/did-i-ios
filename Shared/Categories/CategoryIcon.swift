import Foundation

/// The 12 category icons of `NewCategory.dc.html`, as SF Symbols.
nonisolated enum CategoryIcon: String, CaseIterable, Codable, Sendable {
    case suitcase, sun, home, bin, lock, pill, flame, plug, car, key, heart, globe

    var symbolName: String {
        switch self {
        case .suitcase: "suitcase.fill"
        case .sun: "sun.max.fill"
        case .home: "house.fill"
        case .bin: "trash.fill"
        case .lock: "lock.fill"
        case .pill: "pills.fill"
        case .flame: "flame.fill"
        case .plug: "powerplug.fill"
        case .car: "car.fill"
        case .key: "key.fill"
        case .heart: "heart.fill"
        case .globe: "globe"
        }
    }

    /// The VoiceOver name, "Suitcase icon" in the design.
    var title: String {
        switch self {
        case .suitcase: String(localized: "Suitcase")
        case .sun: String(localized: "Sun")
        case .home: String(localized: "Home")
        case .bin: String(localized: "Bin")
        case .lock: String(localized: "Lock")
        case .pill: String(localized: "Pill")
        case .flame: String(localized: "Flame")
        case .plug: String(localized: "Plug")
        case .car: String(localized: "Car")
        case .key: String(localized: "Key")
        case .heart: String(localized: "Heart")
        case .globe: String(localized: "Globe")
        }
    }
}
