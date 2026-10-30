import Foundation
import SwiftData
import Synchronization

nonisolated enum DidIMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    static var stages: [MigrationStage] { [v1ToV2] }

    /// V1 → V2: every check goes into Daily, which takes the earliest per-check reminder time.
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
            let daily = try CategoryDefaults.dailyModel(in: context, now: Date())
            daily.reminderMinutes = minutes
            for check in try context.fetch(FetchDescriptor<SchemaV2.Check>()) where check.category == nil {
                check.category = daily
            }
            try context.save()
        }
    )

    /// The V1 reminder time, read before V1's column goes and written to Daily after.
    private static let carriedReminderMinutes = Mutex<Int?>(nil)
}
