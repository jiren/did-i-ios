import Foundation

/// The Add sheet's chips: the design's four Daily checks first (until they exist), then `Main.dc.html`'s list.
nonisolated enum CheckSuggestions {
    static let all: [String] = [
        String(localized: "Front door locked"),
        String(localized: "Pill taken"),
        String(localized: "Stove off"),
        String(localized: "Iron unplugged"),
        String(localized: "Car locked"),
        String(localized: "Tap off"),
        String(localized: "Back door locked"),
        String(localized: "Hair tool off"),
        String(localized: "Lights off"),
        String(localized: "Garage shut"),
        String(localized: "Heater off"),
        String(localized: "Keys packed"),
    ]

    /// Suggestions not already a check in any category, in order.
    static func available(excluding existingNames: [String]) -> [String] {
        let existing = Set(existingNames.map(CheckName.key))
        return all.filter { !existing.contains(CheckName.key($0)) }
    }
}
