import Foundation

/// The Add checks sheet's chips (`Main.dc.html`), led by the design's four sample checks.
nonisolated enum CheckSuggestions {
    static let all: [String] = [
        String(localized: "Front door locked"),
        String(localized: "Pill taken"),
        String(localized: "Stove off"),
        String(localized: "Iron unplugged"),
        String(localized: "Windows closed"),
        String(localized: "Car locked"),
        String(localized: "Tap off"),
        String(localized: "Back door locked"),
        String(localized: "Hair tool off"),
        String(localized: "Lights off"),
        String(localized: "Garage shut"),
        String(localized: "Charger unplugged"),
        String(localized: "Heater off"),
    ]

    /// Suggestions not already a check, in order.
    static func available(excluding existingNames: [String]) -> [String] {
        let existing = Set(existingNames.map(CheckName.key))
        return all.filter { !existing.contains(CheckName.key($0)) }
    }
}
