import Foundation
import SwiftData
import WidgetKit

/// What intents use to read and write, in whichever process runs them. The app replaces `shared` at launch with
/// its own store so intents and screens share one context; the widget extension opens its own.
final class IntentServices {
    static var shared = IntentServices.standalone()

    let store: SwiftDataStore?
    let settings: AppSettings
    let photos: PhotoStore
    let timeSource: any TimeSource
    /// After every write: the app tells its screens; the extension tells the app and reloads widgets.
    var afterWrite: () -> Void
    /// Set by the app: open a check's page.
    var openCheck: ((UUID) -> Void)?
    /// Set by the app: show the Logged screen for a log, opening the camera if asked.
    var showLogged: ((LoggedRequest) -> Void)?

    init(store: SwiftDataStore?, settings: AppSettings, photos: PhotoStore, timeSource: any TimeSource, afterWrite: @escaping () -> Void) {
        self.store = store
        self.settings = settings
        self.photos = photos
        self.timeSource = timeSource
        self.afterWrite = afterWrite
    }

    /// For a process without the app's environment: its own container on the shared store.
    static func standalone() -> IntentServices {
        let store = (try? ModelContainer.app()).map { SwiftDataStore(container: $0) }
        return IntentServices(
            store: store,
            settings: AppSettings(defaults: AppGroup.defaults),
            photos: PhotoStore(),
            timeSource: SystemTimeSource()
        ) {
            StoreChangeSignal.post()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func requireStore() throws -> SwiftDataStore {
        guard let store else { throw IntentError.storeUnavailable }
        return store
    }

    var relativeTime: RelativeTime {
        RelativeTime(boundary: settings.dayBoundary)
    }
}

/// The Logged screen to show after an Action Button press.
nonisolated struct LoggedRequest: Identifiable, Hashable, Sendable {
    var id: UUID { logID }
    let logID: UUID
    let opensCamera: Bool
}

nonisolated enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case storeUnavailable
    case checkNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .storeUnavailable: "Did I? couldn’t open your checks."
        case .checkNotFound: "That check isn’t in Did I? any more."
        }
    }
}
