import Foundation
import SwiftData

/// One thing people doubt they did, logged as often as they like.
@Model
final class Check {
    @Attribute(.unique) var id: UUID
    var name: String
    /// A `CheckKind` raw value.
    var kindRaw: String
    /// Position on Today, ascending.
    var order: Int
    /// Minutes after midnight for the daily "if not logged" reminder, or nil for none.
    var reminderMinutes: Int?
    var nudgesOnLeavingHome: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \LogEntry.check)
    var logs: [LogEntry] = []

    init(id: UUID = UUID(), name: String, kind: CheckKind, order: Int, now: Date) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.order = order
        self.reminderMinutes = nil
        self.nudgesOnLeavingHome = false
        self.createdAt = now
        self.updatedAt = now
    }
}
