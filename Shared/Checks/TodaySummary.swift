import Foundation

/// Today's header: "3 of 4 today" and "1 left: Iron unplugged" (`Main.dc.html`).
nonisolated struct TodaySummary: Equatable, Sendable {
    let doneCount: Int
    let total: Int
    /// Names of the checks not logged today, in Today's order.
    let pendingNames: [String]

    init(checks: [CheckRecord], doneIDs: Set<UUID>) {
        total = checks.count
        doneCount = checks.filter { doneIDs.contains($0.id) }.count
        pendingNames = checks.filter { !doneIDs.contains($0.id) }.map(\.name)
    }

    var progressText: String {
        String(localized: "\(doneCount) of \(total) today")
    }

    var summaryText: String {
        switch pendingNames.count {
        case 0: String(localized: "All clear. Nothing to recheck.")
        case 1: String(localized: "1 left: \(pendingNames[0])")
        default: String(localized: "\(pendingNames.count) left to check")
        }
    }

    var isAllClear: Bool { total > 0 && pendingNames.isEmpty }
}
