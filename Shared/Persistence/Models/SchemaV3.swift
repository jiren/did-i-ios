import Foundation
import SwiftData

/// Weekly on several days (phase 22): a category's repeat can hold a set of weekdays. Frozen; the app uses
/// `SchemaV4`.
nonisolated enum SchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [CheckCategory.self, Check.self, LogEntry.self]
    }
}

extension SchemaV3 {
    @Model
    final class CheckCategory {
        @Attribute(.unique) var id: UUID
        var name: String
        var iconRaw: String
        var colourRaw: String
        var repeatKindRaw: String
        var repeatWeekday: Int?
        var repeatWeekdayMask: Int?
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

        init(id: UUID, name: String, repeatKindRaw: String, order: Int, isDefault: Bool, now: Date) {
            self.id = id
            self.name = name
            self.iconRaw = "sun"
            self.colourRaw = "violet"
            self.repeatKindRaw = repeatKindRaw
            self.order = order
            self.isDefault = isDefault
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
