import Foundation
@testable import Did_I

/// A settable clock for tests.
final class FixedTimeSource: TimeSource, @unchecked Sendable {
    var now: Date
    init(_ now: Date) { self.now = now }
}

enum TestTime {
    static let newYork = TimeZone(identifier: "America/New_York")!

    static func calendar(_ timeZone: TimeZone = newYork) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    /// A wall-clock time in New York.
    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0) -> Date {
        calendar().date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
    }

    static func relativeTime(startHour: Int = 0) -> RelativeTime {
        RelativeTime(boundary: DayBoundary(calendar: calendar(), startHour: startHour), locale: Locale(identifier: "en_US"))
    }
}

extension String {
    /// Formatters put a narrow no-break space before AM/PM; tests write a plain space.
    var plainSpaces: String {
        replacingOccurrences(of: "\u{202F}", with: " ").replacingOccurrences(of: "\u{00A0}", with: " ")
    }
}
