import Foundation

/// Siri's answer to "Did I lock the front door?".
nonisolated enum LastLogAnswer {
    static func text(checkName: String, latest: Date?, now: Date, time: RelativeTime) -> String {
        guard let latest else {
            return String(localized: "You haven’t logged \(checkName) yet.")
        }
        if time.boundary.isInSameDay(latest, as: now) {
            return String(localized: "Yes. \(checkName) at \(time.clockTime(latest)), \(time.ago(latest, now: now)).")
        }
        return String(localized: "Not yet today. The last time was \(time.dayAndTime(latest, now: now)).")
    }
}
