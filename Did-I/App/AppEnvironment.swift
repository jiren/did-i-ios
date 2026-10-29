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
    let photos: PhotoStore

    init(configuration: AppLaunchConfiguration, settings: AppSettings, container: ModelContainer) {
        self.configuration = configuration
        self.settings = settings
        self.timeSource = SystemTimeSource()
        self.store = SwiftDataStore(container: container, timeSource: timeSource)
        self.changes = StoreChangeHub(store: store)
        self.photos = configuration.usesInMemoryStore
            ? PhotoStore(folder: URL.temporaryDirectory.appending(path: "DidI-Photos-\(UUID().uuidString)"))
            : PhotoStore()
        self.checkEditor = CheckEditor(store: store, changes: changes, photos: photos)
        IntentServices.shared = IntentServices(
            store: store, settings: settings, photos: photos, timeSource: timeSource
        ) { [changes] in changes.didChange() }
        changes.onChange.append { [store] in ShortcutsIndex.update(with: (try? store.checks()) ?? []) }
        changes.onChange.append { WidgetRefresher.reloadAll() }
        if !configuration.usesInMemoryStore {
            ShortcutsIndex.update(with: (try? store.checks()) ?? [])
        }
        changes.startObservingOtherProcesses()
        PhotoRetention.sweep(logs: store, photos: photos, keep: settings.keepPhotos, now: timeSource.now)
    }

    /// The disk store, or nil with the reason if it can't be opened.
    static func makeContainer(for configuration: AppLaunchConfiguration) -> Result<ModelContainer, Error> {
        Result { try ModelContainer.app(inMemory: configuration.usesInMemoryStore) }
    }
}
