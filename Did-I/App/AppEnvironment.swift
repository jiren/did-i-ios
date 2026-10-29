import Foundation
import SwiftData

/// The composition root: builds the store, settings and services once, and hands them to screens.
final class AppEnvironment {
    let configuration: AppLaunchConfiguration
    let settings: AppSettings
    let store: SwiftDataStore
    let changes: StoreChangeHub
    let timeSource: any TimeSource
    let checkEditor: CheckEditor

    init(configuration: AppLaunchConfiguration, settings: AppSettings, container: ModelContainer) {
        self.configuration = configuration
        self.settings = settings
        self.timeSource = SystemTimeSource()
        self.store = SwiftDataStore(container: container, timeSource: timeSource)
        self.changes = StoreChangeHub(store: store)
        self.checkEditor = CheckEditor(store: store, changes: changes, photos: nil)
        changes.startObservingOtherProcesses()
    }

    /// The disk store, or nil with the reason if it can't be opened.
    static func makeContainer(for configuration: AppLaunchConfiguration) -> Result<ModelContainer, Error> {
        Result { try ModelContainer.app(inMemory: configuration.usesInMemoryStore) }
    }
}
