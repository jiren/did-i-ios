import Foundation
import Observation

/// Settings in the App Group's `UserDefaults` suite, so the widget extension reads the same values.
@Observable
final class AppSettings {
    private let defaults: UserDefaults

    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    /// 0 (midnight) to 5.
    var dayStartHour: Int {
        didSet { defaults.set(dayStartHour, forKey: Key.dayStartHour) }
    }

    var keepPhotos: KeepPhotos {
        didSet { defaults.set(keepPhotos.rawValue, forKey: Key.keepPhotos) }
    }

    /// Lock Screen widgets show only icons and times.
    var hidesNamesOnLockScreen: Bool {
        didSet { defaults.set(hidesNamesOnLockScreen, forKey: Key.hidesNamesOnLockScreen) }
    }

    /// The check an Action Button press (or the control) logs, or nil to ask which.
    var actionButtonCheckID: UUID? {
        didSet { defaults.set(actionButtonCheckID?.uuidString, forKey: Key.actionButtonCheckID) }
    }

    var actionButtonOpensCamera: Bool {
        didSet { defaults.set(actionButtonOpensCamera, forKey: Key.actionButtonOpensCamera) }
    }

    var actionButtonStrongHaptic: Bool {
        didSet { defaults.set(actionButtonStrongHaptic, forKey: Key.actionButtonStrongHaptic) }
    }

    /// Where "leaving home" is measured from, or nil when not set.
    var home: HomeLocation? {
        didSet {
            defaults.set(home?.latitude, forKey: Key.homeLatitude)
            defaults.set(home?.longitude, forKey: Key.homeLongitude)
        }
    }

    /// On leaving home, also tell people about checks they already logged ("You're good.").
    var reassuresOnLeavingHome: Bool {
        didSet { defaults.set(reassuresOnLeavingHome, forKey: Key.reassuresOnLeavingHome) }
    }

    /// Tiles or rows on Today; kept so the choice sticks.
    var todayLayout: TodayLayout {
        didSet { defaults.set(todayLayout.rawValue, forKey: Key.todayLayout) }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        appearance = defaults.string(forKey: Key.appearance).flatMap(Appearance.init) ?? .system
        hidesNamesOnLockScreen = defaults.bool(forKey: Key.hidesNamesOnLockScreen)
        actionButtonCheckID = defaults.string(forKey: Key.actionButtonCheckID).flatMap(UUID.init(uuidString:))
        actionButtonOpensCamera = defaults.bool(forKey: Key.actionButtonOpensCamera)
        actionButtonStrongHaptic = defaults.object(forKey: Key.actionButtonStrongHaptic) as? Bool ?? true
        if let latitude = defaults.object(forKey: Key.homeLatitude) as? Double,
           let longitude = defaults.object(forKey: Key.homeLongitude) as? Double {
            home = HomeLocation(latitude: latitude, longitude: longitude)
        } else {
            home = nil
        }
        reassuresOnLeavingHome = defaults.bool(forKey: Key.reassuresOnLeavingHome)
        keepPhotos = defaults.string(forKey: Key.keepPhotos).flatMap(KeepPhotos.init) ?? .thirtyDays
        dayStartHour = min(max(defaults.integer(forKey: Key.dayStartHour), 0), DayBoundary.latestStartHour)
        todayLayout = defaults.string(forKey: Key.todayLayout).flatMap(TodayLayout.init) ?? .grid
    }

    var dayBoundary: DayBoundary {
        DayBoundary(startHour: dayStartHour)
    }

    private enum Key {
        static let appearance = "appearance"
        static let dayStartHour = "dayStartHour"
        static let keepPhotos = "keepPhotos"
        static let hidesNamesOnLockScreen = "hidesNamesOnLockScreen"
        static let actionButtonCheckID = "actionButtonCheckID"
        static let actionButtonOpensCamera = "actionButtonOpensCamera"
        static let actionButtonStrongHaptic = "actionButtonStrongHaptic"
        static let homeLatitude = "homeLatitude"
        static let homeLongitude = "homeLongitude"
        static let reassuresOnLeavingHome = "reassuresOnLeavingHome"
        static let todayLayout = "todayLayout"
    }
}

nonisolated struct HomeLocation: Equatable, Sendable {
    /// How far from home counts as leaving, in metres.
    static let radius: Double = 150

    var latitude: Double
    var longitude: Double
}
