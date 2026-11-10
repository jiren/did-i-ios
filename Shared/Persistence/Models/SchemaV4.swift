import Foundation
import SwiftData

/// Custom repeat and time of day (phases 26–27): a category can repeat every N days, weeks, months or years, with a
/// start and an end, and belongs to a part of the day.
nonisolated enum SchemaV4: VersionedSchema {
    static let versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [CheckCategory.self, Check.self, LogEntry.self]
    }
}

/// The current models.
typealias CheckCategory = SchemaV4.CheckCategory
typealias Check = SchemaV4.Check
typealias LogEntry = SchemaV4.LogEntry
