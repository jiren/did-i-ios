import Foundation
import SwiftData
import Synchronization

nonisolated enum DidIMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self, SchemaV3.self] }
    static var stages: [MigrationStage] { [v1ToV2, v2ToV3] }

    /// V1 → V2: every check goes into Daily, which takes the earliest per-check reminder time. Works on V2's own
    /// models, so later versions can't change it.
    static let v1ToV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            let minutes = try context.fetch(FetchDescriptor<SchemaV1.Check>()).compactMap(\.reminderMinutes).min()
            carriedReminderMinutes.withLock { $0 = minutes }
        },
        didMigrate: { context in
            let minutes = carriedReminderMinutes.withLock { value in
                defer { value = nil }
                return value
            }
            let id = CategoryDefaults.dailyID
            var descriptor = FetchDescriptor<SchemaV2.CheckCategory>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            let daily: SchemaV2.CheckCategory
            if let existing = try context.fetch(descriptor).first {
                daily = existing
            } else {
                daily = SchemaV2.CheckCategory(dailyWithID: id, name: CategoryDefaults.dailyName, now: Date())
                context.insert(daily)
            }
            daily.reminderMinutes = minutes
            for check in try context.fetch(FetchDescriptor<SchemaV2.Check>()) where check.category == nil {
                check.category = daily
            }
            try context.save()
        }
    )

    /// V2 → V3: adds the weekdays a weekly category repeats on; existing ones keep their one day.
    static let v2ToV3 = MigrationStage.lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self)

    /// The V1 reminder time, read before V1's column goes and written to Daily after.
    private static let carriedReminderMinutes = Mutex<Int?>(nil)
}
