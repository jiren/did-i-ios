import Foundation
import SwiftData

/// Categories (phase 13): every check belongs to one, and reminders moved from checks to categories.
nonisolated enum SchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [CheckCategory.self, Check.self, LogEntry.self]
    }
}

/// The current models.
typealias CheckCategory = SchemaV2.CheckCategory
typealias Check = SchemaV2.Check
typealias LogEntry = SchemaV2.LogEntry
