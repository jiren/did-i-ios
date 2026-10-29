import Foundation

/// How long proof photos are kept; the logs themselves stay.
nonisolated enum KeepPhotos: String, CaseIterable, Identifiable, Sendable {
    case sevenDays, thirtyDays, forever

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sevenDays: String(localized: "7 days")
        case .thirtyDays: String(localized: "30 days")
        case .forever: String(localized: "Forever")
        }
    }

    /// Photos on logs before this are removed, or nil to keep them all.
    func cutoff(before now: Date, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        switch self {
        case .sevenDays: calendar.date(byAdding: .day, value: -7, to: now)
        case .thirtyDays: calendar.date(byAdding: .day, value: -30, to: now)
        case .forever: nil
        }
    }
}
