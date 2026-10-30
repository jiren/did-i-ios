import Foundation
import Testing
@testable import Did_I

/// `Main.dc.html`'s sample: Friday, Oct 30, 2026 at 10:42 AM, four categories and twelve tasks.
private struct Sample {
    static let calendar = TestTime.calendar()
    static let now = TestTime.date(2026, 10, 30, 10, 42)
    static let today = CalendarDay(year: 2026, month: 10, day: 30)

    let daily = category("Daily", .sun, .violet, .daily, order: 0, isDefault: true)
    let bins = category("Bin night", .bin, .mint, .weekly(weekday: 6), order: 1)
    let home = category("Home safety", .home, .coral, .monthly(day: 1), order: 2)
    let travel = category("Travel", .suitcase, .sky, .once(CalendarDay(year: 2026, month: 11, day: 2)), order: 3)
    var checks: [CheckRecord] = []
    var logs: [LogRecord] = []

    init() {
        let names: [(String, CategoryRecord)] = [
            ("Front door locked", daily), ("Pill taken", daily), ("Stove off", daily), ("Iron unplugged", daily),
            ("Bins out", bins), ("Recycling out", bins),
            ("Smoke alarm tested", home), ("Extinguisher checked", home),
            ("Passport packed", travel), ("Charger packed", travel), ("Windows closed", travel), ("Water main off", travel),
        ]
        checks = names.enumerated().map { index, entry in
            CheckRecord(id: UUID(), name: entry.0, kind: .other, order: index, categoryID: entry.1.id, nudgesOnLeavingHome: false)
        }
        logs = [("Front door locked", 8, 42), ("Pill taken", 8, 15), ("Stove off", 8, 30), ("Bins out", 7, 5)].map {
            log($0.0, at: TestTime.date(2026, 10, 30, $0.1, $0.2))
        }
    }

    var categories: [CategoryRecord] { [daily, bins, home, travel] }

    func check(_ name: String) -> CheckRecord { checks.first { $0.name == name }! }

    func log(_ name: String, at date: Date) -> LogRecord {
        LogRecord(id: UUID(), checkID: check(name).id, date: date, source: .app, photoFileName: nil)
    }

    func agenda(day: CalendarDay? = nil, filter: CategoryRecord? = nil, logs extra: [LogRecord] = [], now: Date = Sample.now) -> DayAgenda {
        DayAgenda(
            day: day, filter: filter?.id, categories: categories, checks: checks, logs: logs + extra, now: now,
            boundary: DayBoundary(calendar: Self.calendar), locale: Locale(identifier: "en_US")
        )
    }

    private static func category(
        _ name: String, _ icon: CategoryIcon, _ colour: TileSwatch, _ rule: RepeatRule, order: Int, isDefault: Bool = false
    ) -> CategoryRecord {
        CategoryRecord(
            id: isDefault ? CategoryDefaults.dailyID : UUID(), name: name, icon: icon, colour: colour, rule: rule,
            reminderMinutes: nil, order: order, isDefault: isDefault
        )
    }
}

struct DayAgendaTests {
    private let sample = Sample()

    @Test func todayShowsTheDueCategoriesWithProgress() {
        let agenda = sample.agenda()
        #expect(agenda.isToday)
        #expect(agenda.dateLine == "Today · Fri, Oct 30")
        #expect(agenda.sections.map(\.category.name) == ["Daily", "Bin night"])
        #expect(agenda.sections.map(\.progressText) == ["3/4", "1/2"])
        #expect(agenda.sections.map(\.repeatLabel) == ["Every day", "Every Friday"])
        #expect(agenda.progress.scope == "Today")
        #expect(agenda.progress.main == "4 of 6 done")
        #expect(agenda.progress.pill == .left(2))
        #expect(agenda.progress.pill.text == "2 left")
        #expect(agenda.progress.segments.map(\.isDone) == [true, true, true, false, true, false])
        #expect(agenda.nothingDueText == nil)
    }

    @Test func tileColoursFollowTheWholeList() {
        let agenda = sample.agenda()
        #expect(agenda.sections.flatMap(\.tasks).map(\.swatch) == [.violet, .sun, .coral, .mint, .sky, .pink])
        let filtered = sample.agenda(filter: sample.bins)
        #expect(filtered.sections.flatMap(\.tasks).map(\.swatch) == [.sky, .pink])
    }

    @Test func allClearOnceEveryDueTaskIsLogged() {
        let agenda = sample.agenda(logs: [
            sample.log("Iron unplugged", at: TestTime.date(2026, 10, 30, 9)),
            sample.log("Recycling out", at: TestTime.date(2026, 10, 30, 9, 30)),
        ])
        #expect(agenda.progress.pill == .allClear)
        #expect(agenda.progress.isAllClear)
        #expect(agenda.progress.main == "6 of 6 done")
    }

    @Test func aLogOnAnotherDayDoesntCount() {
        let agenda = sample.agenda(logs: [sample.log("Recycling out", at: TestTime.date(2026, 10, 29, 21))])
        #expect(agenda.sections[1].progressText == "1/2")
    }

    @Test func aFilterShowsOneCategory() {
        let agenda = sample.agenda(filter: sample.bins)
        #expect(agenda.sections.map(\.category.name) == ["Bin night"])
        #expect(agenda.progress.scope == "Bin night · today")
        #expect(agenda.progress.main == "1 of 2 done")
        #expect(agenda.progress.pill == .left(1))
    }

    @Test func aLaterDayIsPlannedNotDone() {
        let saturday = CalendarDay(year: 2026, month: 10, day: 31)
        let agenda = sample.agenda(day: saturday)
        #expect(!agenda.isToday)
        #expect(agenda.dateLine == "Sat, Oct 31")
        #expect(agenda.sections.map(\.category.name) == ["Daily"])
        #expect(agenda.sections[0].tasks.allSatisfy { !$0.isDone })
        #expect(agenda.progress.scope == "All · Sat, Oct 31")
        #expect(agenda.progress.main == "4 checks planned")
        #expect(agenda.progress.pill == .upcoming)
        #expect(sample.agenda(day: saturday, filter: sample.daily).progress.scope == "Daily · Sat, Oct 31")
    }

    @Test func aFilteredCategoryNotDueSaysSo() {
        let agenda = sample.agenda(filter: sample.travel)
        #expect(agenda.sections.isEmpty)
        #expect(agenda.progress.main == "Nothing due")
        #expect(agenda.progress.pill == .freeDay)
        #expect(agenda.progress.scope == "Travel · today")
        #expect(agenda.nothingDueText == "Travel isn’t due on Fri, Oct 30. Check Coming up below.")
    }

    @Test func oneTaskPlanned() {
        let monday = CalendarDay(year: 2026, month: 11, day: 2)
        var sample = Sample()
        sample.checks = [sample.checks[8]]
        #expect(sample.agenda(day: monday, filter: sample.travel).progress.main == "1 check planned")
    }

    @Test func theStripHasSevenDaysWithDotsForExtraCategories() {
        let strip = sample.agenda().strip
        #expect(strip.count == 7)
        #expect(strip.map(\.dayNumber) == [30, 31, 1, 2, 3, 4, 5])
        #expect(strip.map(\.weekdayText) == ["Today", "Sat", "Sun", "Mon", "Tue", "Wed", "Thu"])
        #expect(strip.map(\.dots) == [[.mint], [], [.coral], [.sky], [], [], []])
        #expect(strip.map(\.isSelected) == [true, false, false, false, false, false, false])
        #expect(strip[1].accessibilityLabel == "Sat, Oct 31")
        #expect(strip[2].accessibilityLabel == "Sun, Nov 1, 1 extra categories due")
    }

    @Test func comingUpSkipsWhatsDueOnTheSelectedDay() {
        let today = sample.agenda().comingUp
        #expect(today.map(\.category.name) == ["Home safety", "Travel"])
        #expect(today.map(\.when) == ["Sun", "Mon"])
        #expect(today.map(\.detail) == ["2 checks · Monthly on the 1st", "4 checks · Once · Mon, Nov 2"])

        let saturday = sample.agenda(day: CalendarDay(year: 2026, month: 10, day: 31)).comingUp
        #expect(saturday.map(\.category.name) == ["Home safety", "Travel", "Bin night"])
        #expect(saturday.map(\.when) == ["Sun", "Mon", "Nov 6"])
        #expect(saturday.map(\.isInStrip) == [true, true, false])

        let sunday = sample.agenda(day: CalendarDay(year: 2026, month: 11, day: 1)).comingUp
        #expect(sunday.map(\.category.name) == ["Travel", "Bin night"])
    }

    @Test func comingUpSaysTomorrow() {
        let agenda = sample.agenda(now: TestTime.date(2026, 10, 31, 9))
        #expect(agenda.comingUp.first?.category.name == "Home safety")
        #expect(agenda.comingUp.first?.when == "Tomorrow")
    }

    @Test func theRingCountsTodayWhateverIsSelected() {
        let agenda = sample.agenda(day: CalendarDay(year: 2026, month: 11, day: 2), filter: sample.travel)
        #expect(agenda.todayDoneCount == 4)
        #expect(agenda.todayTotal == 6)
        #expect(agenda.ringAccessibilityLabel == "Today: 4 of 6 checked")
    }

    @Test func aPastDayMeansToday() {
        #expect(sample.agenda(day: CalendarDay(year: 2026, month: 10, day: 1)).selectedDay == Sample.today)
    }

    @Test func aNewInstallHasNothingDue() {
        let agenda = DayAgenda(
            day: nil, filter: nil, categories: [sample.daily], checks: [], logs: [], now: Sample.now,
            boundary: DayBoundary(calendar: Sample.calendar), locale: Locale(identifier: "en_US")
        )
        #expect(agenda.progress.main == "Nothing due")
        #expect(agenda.progress.pill == .freeDay)
        #expect(agenda.comingUp.isEmpty)
    }
}
