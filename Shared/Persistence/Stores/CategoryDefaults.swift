import Foundation
import SwiftData

/// Daily, the category that always exists.
nonisolated enum CategoryDefaults {
    /// Fixed, so every process and the migration agree on which category is Daily.
    static let dailyID = UUID(uuidString: "DA11DA11-0000-4000-8000-000000000001") ?? UUID()

    static var dailyName: String { String(localized: "Daily") }

    /// Daily from `context`, inserted if it isn't there yet (a new install, or the V1 migration). Not saved.
    static func dailyModel(in context: ModelContext, now: Date) throws -> CheckCategory {
        let id = dailyID
        var descriptor = FetchDescriptor<CheckCategory>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let daily = try context.fetch(descriptor).first { return daily }
        let daily = CheckCategory(id: id, name: dailyName, icon: .sun, colour: .violet, rule: .daily, order: 0, isDefault: true, now: now)
        context.insert(daily)
        return daily
    }
}
