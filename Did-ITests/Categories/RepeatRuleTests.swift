import Foundation
import Testing
@testable import Did_I

private let calendar = TestTime.calendar()
private let english = Locale(identifier: "en_US")

private func day(_ year: Int, _ month: Int, _ day: Int) -> CalendarDay {
    CalendarDay(year: year, month: month, day: day)
}

struct RepeatRuleTests {
    // Friday, Oct 30, 2026; New York leaves DST on Sunday, Nov 1.
    private static let friday = 6

    @Test(arguments: [
        (RepeatRule.daily, day(2026, 10, 31), true),
        (.weekly(weekday: friday), day(2026, 10, 30), true),
        (.weekly(weekday: friday), day(2026, 10, 31), false),
        (.weekly(weekday: friday), day(2026, 11, 6), true),
        (.weekly(weekdays: RepeatRule.workingDays), day(2026, 11, 2), true),
        (.weekly(weekdays: RepeatRule.workingDays), day(2026, 10, 31), false),
        (.weekly(weekdays: RepeatRule.weekendDays), day(2026, 10, 31), true),
        (.weekly(weekdays: [2, 4, 6]), day(2026, 11, 4), true),
        (.weekly(weekdays: [2, 4, 6]), day(2026, 11, 3), false),
        (.monthly(day: 1), day(2026, 11, 1), true),
        (.monthly(day: 1), day(2026, 11, 2), false),
        (.monthly(day: 31), day(2026, 11, 30), true),
        (.monthly(day: 31), day(2026, 11, 29), false),
        (.monthly(day: 31), day(2027, 2, 28), true),
        (.monthly(day: 31), day(2026, 12, 31), true),
        (.monthly(day: 31), day(2026, 12, 30), false),
        (.monthly(day: 30), day(2028, 2, 29), true),
        (.yearly(month: 11, day: 6), day(2027, 11, 6), true),
        (.yearly(month: 11, day: 6), day(2027, 10, 6), false),
        (.yearly(month: 2, day: 29), day(2027, 2, 28), true),
        (.yearly(month: 2, day: 29), day(2028, 2, 29), true),
        (.yearly(month: 2, day: 29), day(2028, 2, 28), false),
        (.once(day(2026, 11, 6)), day(2026, 11, 6), true),
        (.once(day(2026, 11, 6)), day(2027, 11, 6), false),
    ])
    func isDue(rule: RepeatRule, on date: CalendarDay, expected: Bool) {
        #expect(rule.isDue(on: date, calendar: calendar) == expected)
    }

    @Test func everyOtherWeekCountsFromItsFirstDayAcrossDST() {
        let rule = RepeatRule.everyTwoWeeks(weekday: Self.friday, startingOnOrAfter: day(2026, 10, 30), calendar: calendar)
        #expect(rule == .everyTwoWeeks(weekday: Self.friday, anchor: day(2026, 10, 30)))
        #expect(rule.isDue(on: day(2026, 10, 30), calendar: calendar))
        #expect(!rule.isDue(on: day(2026, 11, 6), calendar: calendar))
        #expect(rule.isDue(on: day(2026, 11, 13), calendar: calendar))
        #expect(!rule.isDue(on: day(2026, 11, 14), calendar: calendar))
        #expect(rule.isDue(on: day(2027, 3, 19), calendar: calendar))
    }

    @Test func everyOtherWeekStartsOnTheNextMatchingDay() {
        let rule = RepeatRule.everyTwoWeeks(weekday: Self.friday, startingOnOrAfter: day(2026, 10, 31), calendar: calendar)
        #expect(rule == .everyTwoWeeks(weekday: Self.friday, anchor: day(2026, 11, 6)))
    }

    @Test func aDayStartAfterMidnightKeepsTheEveningBefore() {
        let boundary = DayBoundary(calendar: calendar, startHour: 5)
        let oneAMSaturday = TestTime.date(2026, 10, 31, 1)
        #expect(boundary.calendarDay(containing: oneAMSaturday) == day(2026, 10, 30))
        #expect(RepeatRule.weekly(weekday: Self.friday).isDue(on: boundary.calendarDay(containing: oneAMSaturday), calendar: calendar))
        #expect(boundary.interval(of: day(2026, 10, 30)).end == TestTime.date(2026, 10, 31, 5))
    }

    @Test func theDayAcrossDSTIs25Hours() {
        let interval = DayBoundary(calendar: calendar).interval(of: day(2026, 11, 1))
        #expect(interval.duration == 25 * 3600)
    }

    @Test func nextDueDay() {
        #expect(RepeatRule.weekly(weekday: Self.friday).nextDueDay(onOrAfter: day(2026, 10, 31), calendar: calendar) == day(2026, 11, 6))
        #expect(RepeatRule.monthly(day: 31).nextDueDay(onOrAfter: day(2027, 2, 1), calendar: calendar) == day(2027, 2, 28))
        #expect(RepeatRule.once(day(2026, 11, 2)).nextDueDay(onOrAfter: day(2026, 10, 30), calendar: calendar) == day(2026, 11, 2))
        #expect(RepeatRule.once(day(2026, 10, 2)).nextDueDay(onOrAfter: day(2026, 10, 30), calendar: calendar) == nil)
        #expect(RepeatRule.once(day(2026, 10, 2)).isPast(before: day(2026, 10, 30)))
        #expect(!RepeatRule.daily.isPast(before: day(2026, 10, 30)))
    }

    @Test(arguments: [
        (RepeatRule.daily, "Every day"),
        (.weekly(weekday: friday), "Every Friday"),
        (.weekly(weekdays: RepeatRule.workingDays), "Every weekday"),
        (.weekly(weekdays: RepeatRule.weekendDays), "Every weekend"),
        (.weekly(weekdays: [6, 2, 4]), "Every Mon, Wed, Fri"),
        (.weekly(weekdays: Set(1...7)), "Every day"),
        (.everyTwoWeeks(weekday: friday, anchor: day(2026, 10, 30)), "Every other Friday"),
        (.monthly(day: 1), "Monthly on the 1st"),
        (.monthly(day: 22), "Monthly on the 22nd"),
        (.yearly(month: 11, day: 6), "Every year, Nov 6"),
        (.yearly(month: 2, day: 29), "Every year, Feb 29"),
        (.once(day(2026, 11, 6)), "Once · Fri, Nov 6"),
    ])
    func labels(rule: RepeatRule, expected: String) {
        #expect(rule.label(calendar: calendar, locale: english) == expected)
    }
}
