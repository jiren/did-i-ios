import Foundation

/// Rules for the names people give checks.
nonisolated enum CheckName {
    static let maximumLength = 40

    /// Trimmed and capped, or nil when nothing is left.
    static func cleaned(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maximumLength))
    }

    private static let stateWords: Set<String> = [
        "locked", "taken", "off", "unplugged", "closed", "shut", "fed", "done", "watered", "paid", "sent", "out",
    ]

    /// The state a log confirms ("Front door locked" → "Locked"), else "Logged".
    static func state(of name: String) -> String {
        let last = name.split(separator: " ").last.map { $0.lowercased() } ?? ""
        guard stateWords.contains(last) else { return String(localized: "Logged") }
        return last.prefix(1).uppercased() + last.dropFirst()
    }

    /// Case- and whitespace-insensitive, for spotting a check that already exists.
    static func key(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
