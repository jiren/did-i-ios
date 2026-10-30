import Foundation
import SwiftData

extension SchemaV2 {
    /// One thing people doubt they did, logged as often as they like.
    @Model
    final class Check {
        @Attribute(.unique) var id: UUID
        var name: String
        /// A `CheckKind` raw value.
        var kindRaw: String
        /// Position in the whole list, ascending; Today sorts by category, then this.
        var order: Int
        var nudgesOnLeavingHome: Bool
        var createdAt: Date
        var updatedAt: Date
        /// Never nil once stored; the store and the migration put every check in a category.
        var category: CheckCategory?

        @Relationship(deleteRule: .cascade, inverse: \LogEntry.check)
        var logs: [LogEntry] = []

        init(id: UUID = UUID(), name: String, kind: CheckKind, order: Int, category: CheckCategory?, now: Date) {
            self.id = id
            self.name = name
            self.kindRaw = kind.rawValue
            self.order = order
            self.nudgesOnLeavingHome = false
            self.createdAt = now
            self.updatedAt = now
            self.category = category
        }
    }
}
