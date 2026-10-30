import Foundation
import SwiftData

extension ModelContainer {
    /// Where the app and the widget extension keep the store.
    nonisolated static var appStoreURL: URL {
        AppGroup.containerURL.appending(path: "DidI.store")
    }

    /// The one container for every model in `SchemaV3`, on disk at `url` or in memory.
    static func app(inMemory: Bool = false, url: URL = ModelContainer.appStoreURL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let configuration = inMemory
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration(schema: schema, url: url)
        return try ModelContainer(for: schema, migrationPlan: DidIMigrationPlan.self, configurations: [configuration])
    }
}
