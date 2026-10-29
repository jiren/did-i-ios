import Foundation
import Observation

/// Something that wants to hear that checks or logs changed.
protocol ChangeNotifying: AnyObject {
    /// Call after every write, from any screen.
    func didChange()
}

/// One place that knows the data changed: screens watch `version` to reload, and other processes are told.
@Observable
final class StoreChangeHub: ChangeNotifying {
    /// Bumped on every change, here or in the widget extension.
    private(set) var version = 0

    @ObservationIgnored private let store: SwiftDataStore
    @ObservationIgnored private var observer: StoreChangeObserver?
    /// Side effects after any change (widget reloads, reminders), added as later phases need them.
    @ObservationIgnored var onChange: [() -> Void] = []

    init(store: SwiftDataStore) {
        self.store = store
    }

    func startObservingOtherProcesses() {
        guard observer == nil else { return }
        observer = StoreChangeObserver { [weak self] in self?.externalChange() }
    }

    func didChange() {
        version += 1
        StoreChangeSignal.post()
        onChange.forEach { $0() }
    }

    /// The app came back to the foreground; the widget may have written while it was away.
    func refreshFromDisk() {
        store.reloadFromDisk()
        version += 1
    }

    /// The widget extension wrote; it has already reloaded the widgets, so only screens need to hear.
    private func externalChange() {
        refreshFromDisk()
    }
}
