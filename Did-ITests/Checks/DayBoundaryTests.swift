import Foundation
import Testing
@testable import Did_I

struct DayBoundaryTests {
    private let midnight = DayBoundary(calendar: TestTime.calendar(), startHour: 0)
    private let fourAM = DayBoundary(calendar: TestTime.calendar(), startHour: 4)

    @Test func midnightDayRunsMidnightToMidnight() {
        let day = midnight.day(containing: TestTime.date(2026, 10, 29, 8, 42))
        #expect(day.start == TestTime.date(2026, 10, 29))
        #expect(day.end == TestTime.date(2026, 10, 30))
    }

    @Test func oneAMBelongsToTheEveningBeforeWhenTheDayStartsAtFour() {
        let day = fourAM.day(containing: TestTime.date(2026, 10, 30, 1, 0))
        #expect(day.start == TestTime.date(2026, 10, 29, 4))
        #expect(day.end == TestTime.date(2026, 10, 30, 4))
    }

    @Test func fourAMStartsTheNewDay() {
        #expect(fourAM.day(containing: TestTime.date(2026, 10, 30, 4, 0)).start == TestTime.date(2026, 10, 30, 4))
    }

    @Test func springForwardDayIs23Hours() {
        let day = midnight.day(containing: TestTime.date(2026, 3, 8, 12))
        #expect(day.duration == 23 * 3600)
    }

    @Test func fallBackDayIs25Hours() {
        let day = midnight.day(containing: TestTime.date(2026, 11, 1, 12))
        #expect(day.duration == 25 * 3600)
    }

    @Test func aStartHourDSTSkipsMovesToTheNextValidTime() {
        let twoAM = DayBoundary(calendar: TestTime.calendar(), startHour: 2)
        let day = twoAM.day(containing: TestTime.date(2026, 3, 8, 12))
        #expect(day.start == TestTime.date(2026, 3, 8, 3))
    }

    @Test func theNextDaysStartIsNotInToday() {
        let reference = TestTime.date(2026, 10, 29, 9)
        #expect(midnight.isInSameDay(TestTime.date(2026, 10, 29, 23, 59), as: reference))
        #expect(!midnight.isInSameDay(TestTime.date(2026, 10, 30), as: reference))
    }

    @Test(arguments: [-3, 9])
    func startHourIsClamped(hour: Int) {
        let boundary = DayBoundary(calendar: TestTime.calendar(), startHour: hour)
        #expect((0...DayBoundary.latestStartHour).contains(boundary.startHour))
    }
}
