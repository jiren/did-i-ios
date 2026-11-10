import Foundation
import Testing
@testable import Did_I

private let calendar = TestTime.calendar()
private let english = Locale(identifier: "en_US")

private func day(_ year: Int, _ month: Int, _ day: Int) -> CalendarDay {
    CalendarDay(year: year, month: month, day: day)
}

private func custom(
    _ frequency: CustomRepeat.Frequency, every interval: Int = 1, from start: CalendarDay = day(2026, 10, 30),
    end: CustomRepeat.End = .never, weekStart: Int = 1
) -> CustomRepeat {
    CustomRepeat(frequency: frequency, interval: interval, start: start, end: end, weekStart: weekStart)
}

private let sunday = 1, monday = 2, wednesday = 4, thursday = 5, friday = 6

/// Calendar-style repeats (Phase 26). Friday, Oct 30, 2026; New York leaves DST on Nov 1 and enters it on Mar 14, 2027.
struct CustomRepeatTests {
    @Test(arguments: [
        // Every 3 days, across both DST changes.
        (custom(.daily, every: 3), day(2026, 10, 29), false),
        (custom(.daily, every: 3), day(2026, 10, 30), true),
        (custom(.daily, every: 3), day(2026, 11, 1), false),
        (custom(.daily, every: 3), day(2026, 11, 2), true),
        (custom(.daily, every: 3), day(2027, 3, 14), true),
        (custom(.daily, every: 3), day(2027, 3, 15), false),
        // Sun and Wed every 2 weeks from Wed, Nov 4: the week start decides which Sunday is in the first week.
        (custom(.weekly(weekdays: [sunday, wednesday]), every: 2, from: day(2026, 11, 4), weekStart: monday), day(2026, 11, 8), true),
        (custom(.weekly(weekdays: [sunday, wednesday]), every: 2, from: day(2026, 11, 4), weekStart: sunday), day(2026, 11, 8), false),
        (custom(.weekly(weekdays: [sunday, wednesday]), every: 2, from: day(2026, 11, 4), weekStart: monday), day(2026, 11, 15), false),
        (custom(.weekly(weekdays: [sunday, wednesday]), every: 2, from: day(2026, 11, 4), weekStart: sunday), day(2026, 11, 15), true),
        (custom(.weekly(weekdays: [sunday, wednesday]), every: 2, from: day(2026, 11, 4), weekStart: sunday), day(2026, 11, 1), false),
        (custom(.weekly(weekdays: [sunday, wednesday]), every: 2, from: day(2026, 11, 4), weekStart: sunday), day(2026, 11, 11), false),
        (custom(.weekly(weekdays: [sunday, wednesday]), every: 2, from: day(2026, 11, 4), weekStart: sunday), day(2026, 11, 18), true),
        // The 31st every other month from Jan 31: short months fall on their last day, odd months are skipped.
        (custom(.monthly(.day(31)), every: 2, from: day(2027, 1, 31)), day(2027, 1, 31), true),
        (custom(.monthly(.day(31)), every: 2, from: day(2027, 1, 31)), day(2027, 2, 28), false),
        (custom(.monthly(.day(31)), every: 2, from: day(2027, 1, 31)), day(2027, 3, 31), true),
        (custom(.monthly(.day(31)), every: 2, from: day(2027, 1, 31)), day(2027, 4, 30), false),
        (custom(.monthly(.day(31)), every: 2, from: day(2027, 1, 31)), day(2027, 5, 31), true),
        // A weekday of the month.
        (custom(.monthly(.weekday(monday, .first))), day(2026, 11, 2), true),
        (custom(.monthly(.weekday(monday, .first))), day(2026, 11, 9), false),
        (custom(.monthly(.weekday(monday, .first))), day(2026, 12, 7), true),
        (custom(.monthly(.weekday(friday, .last))), day(2026, 11, 27), true),
        (custom(.monthly(.weekday(friday, .last))), day(2026, 11, 20), false),
        (custom(.yearly(month: 11, .weekday(thursday, .fourth))), day(2026, 11, 26), true),
        (custom(.yearly(month: 11, .weekday(thursday, .fourth))), day(2026, 11, 19), false),
        (custom(.yearly(month: 11, .weekday(thursday, .fourth))), day(2027, 11, 25), true),
        (custom(.yearly(month: 2, .weekday(sunday, .last))), day(2027, 2, 28), true),
        // Feb 29 every 2 years from 2028 falls on Feb 28 in 2030.
        (custom(.yearly(month: 2, .day(29)), every: 2, from: day(2028, 2, 29)), day(2029, 2, 28), false),
        (custom(.yearly(month: 2, .day(29)), every: 2, from: day(2028, 2, 29)), day(2030, 2, 28), true),
        (custom(.yearly(month: 2, .day(29)), every: 2, from: day(2028, 2, 29)), day(2032, 2, 29), true),
        (custom(.yearly(month: 2, .day(29)), every: 2, from: day(2028, 2, 29)), day(2032, 2, 28), false),
    ])
    func isDue(rule: CustomRepeat, on date: CalendarDay, expected: Bool) {
        #expect(RepeatRule.custom(rule).isDue(on: date, calendar: calendar) == expected)
    }

    @Test(arguments: [
        // Every day until Nov 5, inclusive.
        (custom(.daily, from: day(2026, 11, 1), end: .on(day(2026, 11, 5))), day(2026, 11, 5), true),
        (custom(.daily, from: day(2026, 11, 1), end: .on(day(2026, 11, 5))), day(2026, 11, 6), false),
        // Every other day, 3 times: Nov 1, 3, 5.
        (custom(.daily, every: 2, from: day(2026, 11, 1), end: .after(3)), day(2026, 11, 5), true),
        (custom(.daily, every: 2, from: day(2026, 11, 1), end: .after(3)), day(2026, 11, 7), false),
        // Mon and Wed from Wed, Nov 4, 3 times: Nov 4, 9, 11.
        (custom(.weekly(weekdays: [monday, wednesday]), from: day(2026, 11, 4), end: .after(3), weekStart: monday), day(2026, 11, 11), true),
        (custom(.weekly(weekdays: [monday, wednesday]), from: day(2026, 11, 4), end: .after(3), weekStart: monday), day(2026, 11, 16), false),
        // The 1st, twice, from Oct 30: Oct 1 was before the start, so Nov 1 and Dec 1.
        (custom(.monthly(.day(1)), end: .after(2)), day(2026, 12, 1), true),
        (custom(.monthly(.day(1)), end: .after(2)), day(2027, 1, 1), false),
    ])
    func ends(rule: CustomRepeat, on date: CalendarDay, expected: Bool) {
        #expect(rule.isDue(on: date, calendar: calendar) == expected)
    }

    @Test func nextDueDayWorksPastTwoYears() {
        let everyFiveYears = RepeatRule.custom(custom(.yearly(month: 11, .day(6)), every: 5))
        #expect(everyFiveYears.nextDueDay(onOrAfter: day(2026, 10, 1), calendar: calendar) == day(2026, 11, 6))
        #expect(everyFiveYears.nextDueDay(onOrAfter: day(2026, 11, 7), calendar: calendar) == day(2031, 11, 6))
        let monthly = RepeatRule.custom(custom(.monthly(.weekday(monday, .first)), every: 3))
        #expect(monthly.nextDueDay(onOrAfter: day(2026, 11, 3), calendar: calendar) == day(2027, 1, 4))
        let everyThreeDays = RepeatRule.custom(custom(.daily, every: 3))
        #expect(everyThreeDays.nextDueDay(onOrAfter: day(2026, 10, 31), calendar: calendar) == day(2026, 11, 2))
    }

    @Test func anEndedRuleIsPast() {
        let threeTimes = RepeatRule.custom(custom(.daily, every: 2, from: day(2026, 11, 1), end: .after(3)))
        #expect(threeTimes.nextDueDay(onOrAfter: day(2026, 11, 5), calendar: calendar) == day(2026, 11, 5))
        #expect(threeTimes.nextDueDay(onOrAfter: day(2026, 11, 6), calendar: calendar) == nil)
        #expect(!threeTimes.isPast(before: day(2026, 11, 5), calendar: calendar))
        #expect(threeTimes.isPast(before: day(2026, 11, 6), calendar: calendar))
        let neverEnds = RepeatRule.custom(custom(.daily, from: day(2030, 1, 1)))
        #expect(!neverEnds.isPast(before: day(2026, 11, 6), calendar: calendar))
    }

    /// `occurrenceIndex` against counting the due days one by one.
    @Test(arguments: [
        custom(.daily, every: 4),
        custom(.weekly(weekdays: [monday, wednesday, friday]), every: 2, from: day(2026, 11, 4), weekStart: monday),
        custom(.weekly(weekdays: [sunday, thursday]), every: 3, from: day(2026, 11, 4), weekStart: sunday),
        custom(.monthly(.day(31)), every: 2),
        custom(.monthly(.day(15)), every: 1, from: day(2026, 11, 20)),
        custom(.monthly(.weekday(friday, .last)), every: 1),
        custom(.yearly(month: 3, .weekday(sunday, .last)), every: 1),
        custom(.yearly(month: 10, .day(1)), every: 1),
    ])
    func occurrenceIndexCounts(rule: CustomRepeat) {
        var seen = 0
        var date = rule.start
        for _ in 0..<(366 * 3) {
            if rule.isDue(on: date, calendar: calendar) {
                #expect(rule.occurrenceIndex(of: date, calendar: calendar) == seen, "\(date)")
                seen += 1
            }
            date = date.adding(days: 1, calendar: calendar)
        }
        #expect(seen > 0)
    }

    @Test(arguments: [sunday, monday])
    func everyTwoWeeksMatchesItsCustomRule(weekStart: Int) {
        let anchor = day(2026, 10, 30)
        let preset = RepeatRule.everyTwoWeeks(weekday: friday, anchor: anchor)
        let customRule = RepeatRule.custom(custom(.weekly(weekdays: [friday]), every: 2, from: anchor, weekStart: weekStart))
        var date = anchor
        for _ in 0..<365 {
            #expect(preset.isDue(on: date, calendar: calendar) == customRule.isDue(on: date, calendar: calendar), "\(date)")
            date = date.adding(days: 1, calendar: calendar)
        }
    }

    @Test func normalizedClampsIntoRange() {
        let rule = CustomRepeat(
            frequency: .weekly(weekdays: []), interval: 0, start: day(2026, 11, 4), end: .on(day(2026, 11, 1)), weekStart: 9
        ).normalized()
        #expect(rule.interval == 1)
        #expect(rule.frequency == .weekly(weekdays: [1]))
        #expect(rule.end == .on(day(2026, 11, 4)))
        #expect(rule.weekStart == 7)
        #expect(CustomRepeat(frequency: .daily, start: day(2026, 11, 4), end: .after(0)).normalized().end == .after(1))
    }

    @Test(arguments: [
        (custom(.daily), "Every day"),
        (custom(.daily, every: 2), "Every other day"),
        (custom(.daily, every: 3), "Every 3 days"),
        (custom(.weekly(weekdays: [friday])), "Every Friday"),
        (custom(.weekly(weekdays: [friday]), every: 2), "Every other Friday"),
        (custom(.weekly(weekdays: [friday]), every: 3), "Every 3 weeks on Friday"),
        (custom(.weekly(weekdays: [wednesday, monday]), every: 2), "Every other week on Mon, Wed"),
        (custom(.weekly(weekdays: [wednesday, monday]), every: 3), "Every 3 weeks on Mon, Wed"),
        (custom(.monthly(.day(1))), "Monthly on the 1st"),
        (custom(.monthly(.weekday(monday, .first))), "Monthly on the first Monday"),
        (custom(.monthly(.weekday(friday, .last)), every: 2), "Every other month on the last Friday"),
        (custom(.monthly(.day(15)), every: 3), "Every 3 months on the 15th"),
        (custom(.yearly(month: 11, .day(6))), "Every year, Nov 6"),
        (custom(.yearly(month: 11, .day(6)), every: 2), "Every other year, Nov 6"),
        (custom(.yearly(month: 11, .day(6)), every: 3), "Every 3 years, Nov 6"),
        (custom(.yearly(month: 11, .weekday(thursday, .fourth))), "Every year on the fourth Thursday of November"),
        (custom(.daily, end: .on(day(2026, 12, 31))), "Every day · until Dec 31"),
        (custom(.daily, end: .on(day(2028, 1, 5))), "Every day · until Jan 5, 2028"),
        (custom(.daily, end: .after(5)), "Every day · 5 times"),
        (custom(.daily, end: .after(1)), "Every day · 1 time"),
    ])
    func labels(rule: CustomRepeat, expected: String) {
        #expect(RepeatRule.custom(rule).label(calendar: calendar, locale: english) == expected)
    }
}
