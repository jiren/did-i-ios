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

    init(defaults: UserDefaults) {
        self.defaults = defaults
        appearance = defaults.string(forKey: Key.appearance).flatMap(Appearance.init) ?? .system
        dayStartHour = min(max(defaults.integer(forKey: Key.dayStartHour), 0), DayBoundary.latestStartHour)
    }

    var dayBoundary: DayBoundary {
        DayBoundary(startHour: dayStartHour)
    }

    private enum Key {
        static let appearance = "appearance"
        static let dayStartHour = "dayStartHour"
    }
}
