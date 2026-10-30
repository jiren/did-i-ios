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

/// What to call a task where tasks from every category are listed together.
nonisolated enum CheckLabels {
    /// "Stove off", or "Stove off · Bedtime" when another category has a task with the same name.
    static func titles(for checks: [CheckRecord], categories: [CategoryRecord]) -> [UUID: String] {
        let names = Dictionary(categories.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let counts = Dictionary(grouping: checks, by: { CheckName.key($0.name) }).mapValues(\.count)
        return Dictionary(uniqueKeysWithValues: checks.map { check in
            let isShared = (counts[CheckName.key(check.name)] ?? 0) > 1
            let category = names[check.categoryID] ?? CategoryDefaults.dailyName
            return (check.id, isShared ? String(localized: "\(check.name) · \(category)") : check.name)
        })
    }
}
