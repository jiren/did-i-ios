import Foundation
import SwiftData

/// Categories (phase 13): every check belongs to one, and reminders moved from checks to categories. Frozen; the
/// app uses `SchemaV4`.
nonisolated enum SchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [CheckCategory.self, Check.self, LogEntry.self]
    }
}

extension SchemaV2 {
    @Model
    final class CheckCategory {
        @Attribute(.unique) var id: UUID
        var name: String
        var iconRaw: String
        var colourRaw: String
        var repeatKindRaw: String
        var repeatWeekday: Int?
        var repeatYear: Int?
        var repeatMonth: Int?
        var repeatDay: Int?
        var reminderMinutes: Int?
        var order: Int
        var isDefault: Bool
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \Check.category)
        var checks: [Check] = []

        /// Daily, as the V1 → V2 migration creates it.
        init(dailyWithID id: UUID, name: String, now: Date) {
            self.id = id
            self.name = name
            self.iconRaw = "sun"
            self.colourRaw = "violet"
            self.repeatKindRaw = "daily"
            self.order = 0
            self.isDefault = true
            self.createdAt = now
            self.updatedAt = now
        }
    }

    @Model
    final class Check {
        @Attribute(.unique) var id: UUID
        var name: String
        var kindRaw: String
        var order: Int
        var nudgesOnLeavingHome: Bool
        var createdAt: Date
        var updatedAt: Date
        var category: CheckCategory?

        @Relationship(deleteRule: .cascade, inverse: \LogEntry.check)
        var logs: [LogEntry] = []

        init(id: UUID = UUID(), name: String, kindRaw: String, order: Int, now: Date) {
            self.id = id
            self.name = name
            self.kindRaw = kindRaw
            self.order = order
            self.nudgesOnLeavingHome = false
            self.createdAt = now
            self.updatedAt = now
        }
    }

    @Model
    final class LogEntry {
        @Attribute(.unique) var id: UUID
        var date: Date
        var sourceRaw: String
        var photoFileName: String?
        var check: Check?
        var updatedAt: Date

        init(id: UUID = UUID(), date: Date, sourceRaw: String, photoFileName: String?, check: Check) {
            self.id = id
            self.date = date
            self.sourceRaw = sourceRaw
            self.photoFileName = photoFileName
            self.check = check
            self.updatedAt = date
        }
    }
}
