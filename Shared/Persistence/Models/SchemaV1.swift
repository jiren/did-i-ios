import Foundation
import SwiftData

/// The first schema (phases 0–12): checks and logs, no categories. Frozen; the app uses `SchemaV2`.
nonisolated enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Check.self, LogEntry.self]
    }
}

extension SchemaV1 {
    @Model
    final class Check {
        @Attribute(.unique) var id: UUID
        var name: String
        var kindRaw: String
        var order: Int
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

    @Model
    final class LogEntry {
        @Attribute(.unique) var id: UUID
        var date: Date
        var sourceRaw: String
        var photoFileName: String?
        var check: Check?
        var updatedAt: Date

        init(id: UUID = UUID(), date: Date, source: LogSource, photoFileName: String?, check: Check) {
            self.id = id
            self.date = date
            self.sourceRaw = source.rawValue
            self.photoFileName = photoFileName
            self.check = check
            self.updatedAt = date
        }
    }
}
