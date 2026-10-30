import Foundation

/// Siri's answer to "Did I lock the front door?".
nonisolated enum LastLogAnswer {
    /// - Parameter isDueToday: whether the task's category is due today; a log today answers either way.
    static func text(checkName: String, latest: Date?, now: Date, time: RelativeTime, isDueToday: Bool = true) -> String {
        if let latest, time.boundary.isInSameDay(latest, as: now) {
            return String(localized: "Yes. \(checkName) at \(time.clockTime(latest)), \(time.ago(latest, now: now)).")
        }
        guard isDueToday else {
            guard let latest else { return String(localized: "\(checkName) isn’t due today.") }
            return String(localized: "Not due today. Last done \(time.dayAndTime(latest, now: now)).")
        }
        guard let latest else {
            return String(localized: "You haven’t logged \(checkName) yet.")
        }
        return String(localized: "Not yet today. The last time was \(time.dayAndTime(latest, now: now)).")
    }
}
