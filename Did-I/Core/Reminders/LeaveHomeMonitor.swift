import CoreLocation
import Foundation

/// Watches for leaving home and nudges about checks with "Nudge me when I leave home" on.
/// The monitor is recreated under the same name at every launch, since iOS relaunches the app to deliver exits.
final class LeaveHomeMonitor {
    /// Letters and digits only: CLMonitor rejects names with dots or hyphens.
    private static let monitorName = "DidIHome"
    private static let homeIdentifier = "home"

    private let store: SwiftDataStore
    private let settings: AppSettings
    private let scheduler: ReminderScheduler
    private let timeSource: any TimeSource
    private var task: Task<Void, Never>?
    private var session: CLServiceSession?
    /// Only one `CLMonitor` may exist per name, so every caller shares this one.
    private lazy var monitor = Task { await CLMonitor(Self.monitorName) }

    init(store: SwiftDataStore, settings: AppSettings, scheduler: ReminderScheduler, timeSource: any TimeSource) {
        self.store = store
        self.settings = settings
        self.scheduler = scheduler
        self.timeSource = timeSource
    }

    /// Starts watching when a home is set and some check wants the nudge; stops otherwise.
    func update() {
        let wantsNudge = ((try? store.checks()) ?? []).contains(where: \.nudgesOnLeavingHome)
        guard let home = settings.home, wantsNudge else {
            stop()
            return
        }
        guard task == nil else { return }
        session = CLServiceSession(authorization: .always)
        task = Task { [weak self] in
            await self?.watch(home)
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        session = nil
        Task {
            await monitor.value.remove(Self.homeIdentifier)
        }
    }

    /// Home moved: watch the new place.
    func restart() {
        stop()
        update()
    }

    private func watch(_ home: HomeLocation) async {
        let monitor = await monitor.value
        let condition = CLMonitor.CircularGeographicCondition(
            center: CLLocationCoordinate2D(latitude: home.latitude, longitude: home.longitude),
            radius: HomeLocation.radius
        )
        await monitor.add(condition, identifier: Self.homeIdentifier, assuming: .satisfied)
        do {
            for try await event in await monitor.events where event.identifier == Self.homeIdentifier {
                if event.state == .unsatisfied { await leftHome() }
            }
        } catch {
            return
        }
    }

    private func leftHome() async {
        guard let checks = try? store.checks(), let categories = try? store.categories(),
              let latest = try? store.latestLogs() else { return }
        let boundary = settings.dayBoundary
        let due = DueTasks.ids(
            on: boundary.calendarDay(containing: timeSource.now), categories: categories, checks: checks, calendar: boundary.calendar
        )
        let nudges = LeaveHomeNudge.notifications(
            checks: checks, dueIDs: due, latestLogs: latest, now: timeSource.now,
            time: RelativeTime(boundary: settings.dayBoundary), reassures: settings.reassuresOnLeavingHome
        )
        await scheduler.post(nudges)
    }
}

/// One fix of where the device is now, for setting home.
enum CurrentLocation {
    static func fetch() async throws -> CLLocationCoordinate2D? {
        let session = CLServiceSession(authorization: .whenInUse)
        defer { _ = session }
        for try await update in CLLocationUpdate.liveUpdates() {
            if update.authorizationDenied || update.authorizationDeniedGlobally { return nil }
            if let location = update.location, location.horizontalAccuracy <= 100 {
                return location.coordinate
            }
        }
        return nil
    }
}
