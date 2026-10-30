import Foundation
import SwiftData
import UserNotifications

/// The composition root: builds the store, settings and services once, and hands them to screens.
final class AppEnvironment {
    let configuration: AppLaunchConfiguration
    let settings: AppSettings
    let store: SwiftDataStore
    let changes: StoreChangeHub
    let timeSource: any TimeSource
    let checkEditor: CheckEditor
    let categoryEditor: CategoryEditor
    let photos: PhotoStore
    let reminders: ReminderScheduler
    let leaveHome: LeaveHomeMonitor
    private let notifications: NotificationHandler

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
        self.categoryEditor = CategoryEditor(store: store, changes: changes, photos: photos)
        IntentServices.shared = IntentServices(
            store: store, settings: settings, photos: photos, timeSource: timeSource
        ) { [changes] in changes.didChange() }
        changes.onChange.append { [store] in ShortcutsIndex.update(with: (try? store.checks()) ?? []) }
        changes.onChange.append { WidgetRefresher.reloadAll() }
        self.reminders = ReminderScheduler()
        self.leaveHome = LeaveHomeMonitor(store: store, settings: settings, scheduler: reminders, timeSource: timeSource)
        self.notifications = NotificationHandler(store: store, changes: changes, timeSource: timeSource)
        ReminderScheduler.registerCategory()
        UNUserNotificationCenter.current().delegate = notifications
        changes.onChange.append { [weak self] in
            self?.rescheduleReminders()
            self?.leaveHome.update()
        }
        if !configuration.usesInMemoryStore {
            rescheduleReminders()
            leaveHome.update()
        }
        if !configuration.usesInMemoryStore {
            ShortcutsIndex.update(with: (try? store.checks()) ?? [])
        }
        changes.startObservingOtherProcesses()
        PhotoRetention.sweep(logs: store, photos: photos, keep: settings.keepPhotos, now: timeSource.now)
    }

    /// Brings pending reminders in line with the checks and today's logs, and books the next background refresh.
    func rescheduleReminders() {
        let now = timeSource.now
        Task { [store, settings, reminders] in
            await reminders.reschedule(store: store, settings: settings, now: now)
        }
        BackgroundRefresh.schedule(after: settings.dayBoundary.day(containing: now).end)
    }

    /// The disk store, or nil with the reason if it can't be opened.
    static func makeContainer(for configuration: AppLaunchConfiguration) -> Result<ModelContainer, Error> {
        Result { try ModelContainer.app(inMemory: configuration.usesInMemoryStore) }
    }
}
