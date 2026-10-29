import Foundation

/// What a check is about; it picks the icon.
nonisolated enum CheckKind: String, CaseIterable, Codable, Sendable {
    case door, car, garage, window, tap, light, pill, stove, plug, other

    var symbolName: String {
        switch self {
        case .door: "lock.fill"
        case .car: "car.fill"
        case .garage: "door.garage.closed"
        case .window: "window.vertical.closed"
        case .tap: "drop.fill"
        case .light: "lightbulb.fill"
        case .pill: "pills.fill"
        case .stove: "flame.fill"
        case .plug: "powerplug.fill"
        case .other: "checkmark.circle.fill"
        }
    }

    var title: String {
        switch self {
        case .door: String(localized: "Lock")
        case .car: String(localized: "Car")
        case .garage: String(localized: "Garage")
        case .window: String(localized: "Window")
        case .tap: String(localized: "Water")
        case .light: String(localized: "Light")
        case .pill: String(localized: "Pill")
        case .stove: String(localized: "Flame")
        case .plug: String(localized: "Plug")
        case .other: String(localized: "Check")
        }
    }

    /// Keywords tried in order, so "Car locked" is a car before it's a lock.
    private static let keywords: [(CheckKind, [String])] = [
        (.car, ["car"]),
        (.garage, ["garage"]),
        (.window, ["window"]),
        (.door, ["door", "lock", "gate"]),
        (.tap, ["tap", "faucet", "water"]),
        (.light, ["light", "lamp"]),
        (.pill, ["pill", "medic", "vitamin", "tablet", "dose"]),
        (.stove, ["stove", "oven", "hob", "gas", "cooker", "grill"]),
        (.plug, ["iron", "plug", "charger", "hair", "heater", "straightener"]),
    ]

    /// The kind a check's name suggests, else `.other`.
    static func suggested(forName name: String) -> CheckKind {
        let lowered = name.lowercased()
        return keywords.first { _, words in words.contains { lowered.contains($0) } }?.0 ?? .other
    }
}
