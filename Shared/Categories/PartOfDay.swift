import Foundation

/// When in the day a category's tasks happen (Phase 26–27): Today groups its sections under these, in this order.
/// There's no Night: it would cross the Day starts at boundary.
nonisolated enum PartOfDay: String, CaseIterable, Codable, Hashable, Sendable {
    case morning, afternoon, evening, anytime

    var title: String {
        switch self {
        case .morning: String(localized: "Morning")
        case .afternoon: String(localized: "Afternoon")
        case .evening: String(localized: "Evening")
        case .anytime: String(localized: "Anytime")
        }
    }

    /// Today's order: Morning, Afternoon, Evening, then Anytime.
    var sortIndex: Int {
        switch self {
        case .morning: 0
        case .afternoon: 1
        case .evening: 2
        case .anytime: 3
        }
    }

    /// The reminder time a category starts with when Remind me is turned on: 9 AM, 3 PM, else 8 PM (as drawn).
    var defaultReminderMinutes: Int {
        switch self {
        case .morning: 9 * 60
        case .afternoon: 15 * 60
        case .evening, .anytime: 20 * 60
        }
    }
}
