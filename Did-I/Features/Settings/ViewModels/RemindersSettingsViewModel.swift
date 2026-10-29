import CoreLocation
import Foundation
import Observation

/// Settings › Reminders: notification access, home, and which checks remind or nudge.
@Observable
final class RemindersSettingsViewModel {
    private(set) var notificationStatus: NotificationPermission.Status = .notAsked
    private(set) var reminderLines: [String] = []
    private(set) var nudgeNames: [String] = []
    private(set) var isLocating = false
    private(set) var locationMessage: String?

    @ObservationIgnored let settings: AppSettings
    @ObservationIgnored private let store: any CheckStoring
    @ObservationIgnored private let monitor: LeaveHomeMonitor?
    @ObservationIgnored private let locale: Locale

    init(settings: AppSettings, store: any CheckStoring, monitor: LeaveHomeMonitor?, locale: Locale = .autoupdatingCurrent) {
        self.settings = settings
        self.store = store
        self.monitor = monitor
        self.locale = locale
    }

    var hasHome: Bool { settings.home != nil }

    func load() async {
        notificationStatus = await NotificationPermission.status()
        let checks = (try? store.checks()) ?? []
        let time = RelativeTime(boundary: settings.dayBoundary, locale: locale)
        reminderLines = checks.compactMap { check in
            guard let minutes = check.reminderMinutes else { return nil }
            let date = settings.dayBoundary.calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
            return String(localized: "\(check.name) · \(time.clockTime(date))")
        }
        nudgeNames = checks.filter(\.nudgesOnLeavingHome).map(\.name)
    }

    func allowNotifications() async {
        notificationStatus = await NotificationPermission.request()
    }

    func setHomeHere() async {
        isLocating = true
        defer { isLocating = false }
        do {
            guard let coordinate = try await CurrentLocation.fetch() else {
                locationMessage = String(localized: "Location access is off. Turn it on in Settings to set home.")
                return
            }
            settings.home = HomeLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            locationMessage = String(localized: "Home is set to where you are now.")
            monitor?.restart()
        } catch {
            locationMessage = String(localized: "Couldn’t find where you are. Try again outside or near a window.")
        }
    }

    func forgetHome() {
        settings.home = nil
        locationMessage = nil
        monitor?.update()
    }
}
