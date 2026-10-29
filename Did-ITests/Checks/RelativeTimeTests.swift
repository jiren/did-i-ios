import Foundation
import Testing
@testable import Did_I

struct RelativeTimeTests {
    private let time = TestTime.relativeTime()
    private let now = TestTime.date(2026, 10, 29, 10, 42)

    @Test(arguments: [
        (0, "Just now") as (Int, String),
        (59, "Just now"),
        (60, "1m ago"),
        (720, "12m ago"),
        (7200, "2h ago"),
        (8820, "2h 27m ago"),
        (259_200, "3d ago"),
    ])
    func ago(seconds: Int, expected: String) {
        #expect(time.ago(now.addingTimeInterval(-Double(seconds)), now: now) == expected)
    }

    @Test func aFutureDateIsJustNow() {
        #expect(time.ago(now.addingTimeInterval(30), now: now) == "Just now")
    }

    @Test func clockTimes() {
        let date = TestTime.date(2026, 10, 29, 8, 42, 7)
        #expect(time.clockTime(date).plainSpaces == "8:42 AM")
        #expect(time.clockTimeWithSeconds(date).plainSpaces == "8:42:07 AM")
        #expect(time.weekday(date) == "Thursday")
    }

    @Test func dayAndTime() {
        #expect(time.dayAndTime(TestTime.date(2026, 10, 29, 8, 42), now: now).plainSpaces == "Today, 8:42 AM")
        #expect(time.dayAndTime(TestTime.date(2026, 10, 28, 22, 58), now: now).plainSpaces == "Yesterday, 10:58 PM")
        #expect(time.dayName(TestTime.date(2026, 10, 27, 8, 37), now: now) == "Tue, Oct 27")
    }

    @Test func aLateNightLogIsTodayWhenTheDayStartsLater() {
        let late = TestTime.relativeTime(startHour: 4)
        let oneAM = TestTime.date(2026, 10, 30, 1)
        #expect(late.dayName(TestTime.date(2026, 10, 29, 22), now: oneAM) == "Today")
    }
}
