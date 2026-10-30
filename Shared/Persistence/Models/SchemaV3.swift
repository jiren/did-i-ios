import Foundation
import SwiftData

/// Weekly on several days (phase 22): a category's repeat can hold a set of weekdays.
nonisolated enum SchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [CheckCategory.self, Check.self, LogEntry.self]
    }
}

/// The current models.
typealias CheckCategory = SchemaV3.CheckCategory
typealias Check = SchemaV3.Check
typealias LogEntry = SchemaV3.LogEntry
