import Foundation
import Testing
@testable import Did_I

/// Monday, Nov 2, 2026 at 10 AM in New York, with Sunday-first weeks. Clocks went back on Nov 1.
private enum Fixture {
    static let now = TestTime.date(2026, 11, 2, 10)
    static let boundary = DayBoundary(calendar: TestTime.calendar())
    static let locale = Locale(identifier: "en_US")
    static let longAgo = TestTime.date(2020, 1, 1)
    static let daily = category("Daily", .daily, order: 0, isDefault: true)

    static func category(_ name: String, _ rule: RepeatRule, order: Int = 1, isDefault: Bool = false) -> CategoryRecord {
        CategoryRecord(
            id: isDefault ? CategoryDefaults.dailyID : UUID(), name: name, icon: .sun, colour: .violet, rule: rule,
            reminderMinutes: nil, order: order, isDefault: isDefault
        )
    }

    static func check(_ name: String, in category: CategoryRecord = daily, order: Int = 0, created: Date = longAgo, kind: CheckKind = .other) -> CheckRecord {
        CheckRecord(id: UUID(), name: name, kind: kind, order: order, categoryID: category.id, nudgesOnLeavingHome: false, createdAt: created)
    }

    static func log(_ check: CheckRecord, _ date: Date, source: LogSource = .app, photo: String? = nil) -> LogRecord {
        LogRecord(id: UUID(), checkID: check.id, date: date, source: source, photoFileName: photo)
    }

    /// Nov 2 at `hour`, or `daysAgo` days earlier.
    static func date(daysAgo: Int = 0, hour: Int = 8, minute: Int = 0) -> Date {
        let day = CalendarDay(year: 2026, month: 11, day: 2).adding(days: -daysAgo, calendar: TestTime.calendar())
        return TestTime.date(day.year, day.month, day.day, hour, minute)
    }

    static func report(
        _ range: StatsRange = .week,
        categories: [CategoryRecord] = [daily],
        checks: [CheckRecord],
        logs: [LogRecord] = [],
        now: Date = now,
        boundary: DayBoundary = boundary
    ) -> StatsReport {
        StatsReport(range: range, categories: categories, checks: checks, logs: logs, now: now, boundary: boundary, locale: locale)
    }
}

struct StatsPeriodsTests {
    @Test func aWeekIsSevenDaysEndingToday() {
        let bars = Fixture.report(.week, checks: []).bars
        #expect(bars.map(\.label) == ["Tue", "Wed", "Thu", "Fri", "Sat", "Sun", "Mon"])
        #expect(bars.first?.detail == "Tue, Oct 27")
        #expect(bars.last?.detail == "Today")
    }

    @Test func aMonthIsFourWholeWeeksAndThisOne() {
        let bars = Fixture.report(.month, checks: []).bars
        #expect(bars.map(\.label) == ["W1", "W2", "W3", "W4", "Now"])
        #expect(bars.map(\.detail) == ["Oct 4–10", "Oct 11–17", "Oct 18–24", "Oct 25–31", "This week"])
    }

    @Test func aWeekAcrossTwoMonthsNamesBoth() {
        let bars = Fixture.report(.month, checks: [], now: TestTime.date(2026, 10, 8, 10)).bars
        #expect(bars[3].detail == "Sep 27–Oct 3")
    }

    @Test func aYearIsTwelveMonthsEndingWithThisOne() {
        let bars = Fixture.report(.year, checks: []).bars
        #expect(bars.map(\.label) == ["D", "J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N"])
        #expect(Set(bars.map(\.id)).count == 12)
        #expect(bars.first?.detail == "Dec 2025")
        #expect(bars[1].detail == "Jan")
        #expect(bars.last?.detail == "Nov so far")
    }

    @Test func aYearInJanuaryStartsLastFebruary() {
        let bars = Fixture.report(.year, checks: [], now: TestTime.date(2027, 1, 15, 10)).bars
        #expect(bars.first?.detail == "Feb 2026")
        #expect(bars[10].detail == "Dec 2026")
        #expect(bars.last?.detail == "Jan so far")
    }

    @Test func aWeekStartsOnTheCalendarsFirstWeekday() {
        var calendar = TestTime.calendar()
        calendar.firstWeekday = 2
        let bars = Fixture.report(.month, checks: [], boundary: DayBoundary(calendar: calendar)).bars
        #expect(bars.map(\.detail) == ["Oct 5–11", "Oct 12–18", "Oct 19–25", "Oct 26–Nov 1", "This week"])
    }
}

struct StatsShareTests {
    @Test func aBarIsTheShareOfDueTasksLogged() {
        let door = Fixture.check("Door", order: 0)
        let pill = Fixture.check("Pill", order: 1)
        let report = Fixture.report(checks: [door, pill], logs: [
            Fixture.log(door, Fixture.date(daysAgo: 2)),
            Fixture.log(door, Fixture.date(daysAgo: 1)),
            Fixture.log(pill, Fixture.date(daysAgo: 1)),
        ])
        #expect(report.bars.map(\.percent) == [0, 0, 0, 0, 50, 100, 0])
        #expect(report.bars[4].tip == "Sat, Oct 31 · 50% logged")
    }

    @Test func manyLogsInADayCountOnce() {
        let door = Fixture.check("Door", order: 0)
        let pill = Fixture.check("Pill", order: 1)
        let report = Fixture.report(checks: [door, pill], logs: [
            Fixture.log(door, Fixture.date(hour: 8)),
            Fixture.log(door, Fixture.date(hour: 9)),
        ])
        #expect(report.bars.last?.percent == 50)
    }

    @Test func aTaskIsNotDueBeforeItWasCreated() {
        let door = Fixture.check("Door", created: Fixture.date(daysAgo: 1, hour: 20))
        let bars = Fixture.report(checks: [door], logs: [Fixture.log(door, Fixture.date(daysAgo: 1, hour: 21))]).bars
        #expect(bars[4].percent == nil)
        #expect(bars[4].valueText == "Nothing due")
        #expect(bars[5].percent == 100)
    }

    @Test func aLogBeforeTheCreationDateCountsFromThatLog() {
        let door = Fixture.check("Door", created: Fixture.date())
        let bars = Fixture.report(checks: [door], logs: [Fixture.log(door, Fixture.date(daysAgo: 2))]).bars
        #expect(bars[3].percent == nil)
        #expect(bars[4].percent == 100)
        #expect(bars[5].percent == 0)
    }

    @Test func aDayWithNothingDueHasNoBarAndStaysOutOfTheAverage() {
        let friday = Fixture.category("Friday", .weekly(weekday: 6))
        let bins = Fixture.check("Bins", in: friday)
        let report = Fixture.report(categories: [Fixture.daily, friday], checks: [bins], logs: [Fixture.log(bins, TestTime.date(2026, 10, 30, 7))])
        #expect(report.bars.map(\.percent) == [nil, nil, nil, 100, nil, nil, nil])
        #expect(report.average == 100)
    }

    @Test func aLogOnADayNotDueCountsOnlyAsALog() {
        let friday = Fixture.category("Friday", .weekly(weekday: 6))
        let bins = Fixture.check("Bins", in: friday)
        let report = Fixture.report(categories: [Fixture.daily, friday], checks: [bins], logs: [Fixture.log(bins, Fixture.date(daysAgo: 1))])
        #expect(report.bars[5].percent == nil)
        #expect(report.bars[3].percent == 0)
        #expect(report.methods.map(\.count) == [1])
    }

    @Test func theAverageIsTheMeanOfTheBars() {
        let door = Fixture.check("Door", order: 0, created: Fixture.date(daysAgo: 1))
        let pill = Fixture.check("Pill", order: 1, created: Fixture.date(daysAgo: 1))
        let report = Fixture.report(checks: [door, pill], logs: [
            Fixture.log(door, Fixture.date(daysAgo: 1)),
            Fixture.log(door, Fixture.date()),
            Fixture.log(pill, Fixture.date()),
        ])
        #expect(report.average == 75)
    }

    @Test func withNoTasksThereIsNoAverage() {
        #expect(Fixture.report(checks: []).average == nil)
    }

    @Test(arguments: [(199, 200, 99), (1, 1000, 1), (1, 2, 50), (2, 2, 100), (0, 5, 0), (0, 0, 0)])
    func percents(part: Int, whole: Int, expected: Int) {
        #expect(StatsReport.percent(part, of: whole) == expected)
    }

    @Test func theLateEveningOfALongDayStaysInThatDay() {
        let door = Fixture.check("Door")
        let bars = Fixture.report(checks: [door], logs: [Fixture.log(door, TestTime.date(2026, 11, 1, 23, 30))]).bars
        #expect(bars[5].percent == 100)
        #expect(bars[6].percent == 0)
    }

    @Test func theDayStartMovesALateLogToTheDayBefore() {
        let door = Fixture.check("Door")
        let boundary = DayBoundary(calendar: TestTime.calendar(), startHour: 5)
        let bars = Fixture.report(checks: [door], logs: [Fixture.log(door, Fixture.date(hour: 1))], boundary: boundary).bars
        #expect(bars[5].percent == 100)
        #expect(bars[6].percent == 0)
    }
}

struct StatsStreakTests {
    private let door = Fixture.check("Door")

    private func logs(daysAgo: [Int]) -> [LogRecord] {
        daysAgo.map { Fixture.log(door, Fixture.date(daysAgo: $0)) }
    }

    @Test func anUnfinishedTodayDoesNotBreakTheRun() {
        #expect(Fixture.report(checks: [door], logs: logs(daysAgo: [1, 2, 3])).streak == 3)
    }

    @Test func aFinishedTodayCounts() {
        #expect(Fixture.report(checks: [door], logs: logs(daysAgo: [0, 1, 2, 3])).streak == 4)
    }

    @Test func aMissedDayEndsTheRun() {
        #expect(Fixture.report(checks: [door], logs: logs(daysAgo: [1, 3, 4])).streak == 1)
        #expect(Fixture.report(checks: [door], logs: logs(daysAgo: [2, 3])).streak == 0)
    }

    @Test func aDayWithNothingDueIsSkipped() {
        let some = Fixture.category("Mon and Wed", .weekly(weekdays: [2, 4]))
        let gym = Fixture.check("Gym", in: some)
        let logs = [TestTime.date(2026, 10, 28, 8), TestTime.date(2026, 10, 26, 8)].map { Fixture.log(gym, $0) }
        #expect(Fixture.report(categories: [Fixture.daily, some], checks: [gym], logs: logs).streak == 2)
    }

    @Test func everyDueTaskMustBeLogged() {
        let pill = Fixture.check("Pill", order: 1)
        let logs = logs(daysAgo: [1, 2]) + [Fixture.log(pill, Fixture.date(daysAgo: 2))]
        #expect(Fixture.report(checks: [door, pill], logs: logs).streak == 0)
    }

    @Test func aNewTaskDoesNotBreakEarlierDays() {
        let pill = Fixture.check("Pill", order: 1, created: Fixture.date())
        #expect(Fixture.report(checks: [door, pill], logs: logs(daysAgo: [1, 2])).streak == 2)
    }

    @Test func noLogsMeansNoStreak() {
        #expect(Fixture.report(checks: [door]).streak == 0)
    }

    @Test func aRareScheduleWithAnOldTaskStillEnds() {
        let yearly = Fixture.category("Yearly", .yearly(month: 3, day: 1))
        let check = CheckRecord(id: UUID(), name: "Boiler", kind: .other, order: 0, categoryID: yearly.id, nudgesOnLeavingHome: false)
        #expect(check.createdAt == .distantPast)
        let log = Fixture.log(check, TestTime.date(2026, 3, 1, 8))
        #expect(Fixture.report(categories: [Fixture.daily, yearly], checks: [check], logs: [log]).streak == 1)
    }

    @Test(arguments: StatsRange.allCases)
    func theStreakIsTheSameOnEveryRange(range: StatsRange) {
        #expect(Fixture.report(range, checks: [door], logs: logs(daysAgo: [1, 2, 3])).streak == 3)
    }

    @Test func theDayStartAppliesToTheRun() {
        let boundary = DayBoundary(calendar: TestTime.calendar(), startHour: 5)
        let late = Fixture.log(door, Fixture.date(hour: 1))
        #expect(Fixture.report(checks: [door], logs: [late], boundary: boundary).streak == 1)
    }
}

struct StatsSecondGuessTests {
    private let stove = Fixture.check("Stove off", order: 0, kind: .stove)

    @Test(arguments: [
        (3, 5, StatsReport.Trend.down(percent: 40)),
        (0, 3, .down(percent: 100)),
        (5, 4, .up(percent: 25)),
        (4, 4, .same),
        (2, 0, .noComparison(count: 2)),
        (0, 0, .noComparison(count: 0)),
    ])
    func trends(current: Int, previous: Int, expected: StatsReport.Trend) {
        #expect(StatsReport.trend(current: current, previous: previous) == expected)
    }

    @Test func aReLogIsWithinThirtyMinutesOfThePreviousLog() {
        let report = Fixture.report(checks: [stove], logs: [
            Fixture.log(stove, Fixture.date(hour: 8, minute: 0)),
            Fixture.log(stove, Fixture.date(hour: 8, minute: 30)),
            Fixture.log(stove, Fixture.date(hour: 9, minute: 1)),
        ])
        #expect(report.trend == .noComparison(count: 1))
    }

    @Test func anotherTasksLogIsNotAReLog() {
        let door = Fixture.check("Door", order: 1)
        let report = Fixture.report(checks: [stove, door], logs: [
            Fixture.log(stove, Fixture.date(hour: 8, minute: 0)),
            Fixture.log(door, Fixture.date(hour: 8, minute: 5)),
        ])
        #expect(report.trend == .noComparison(count: 0))
    }

    @Test func aReLogAcrossMidnightCounts() {
        let report = Fixture.report(checks: [stove], logs: [
            Fixture.log(stove, Fixture.date(daysAgo: 1, hour: 23, minute: 50)),
            Fixture.log(stove, Fixture.date(hour: 0, minute: 10)),
        ])
        #expect(report.trend == .noComparison(count: 1))
    }

    @Test func thePeriodComparesWithTheOneBeforeIt() {
        func pair(daysAgo: Int) -> [LogRecord] {
            [Fixture.log(stove, Fixture.date(daysAgo: daysAgo, hour: 8)), Fixture.log(stove, Fixture.date(daysAgo: daysAgo, hour: 8, minute: 10))]
        }
        // One re-log this week, two in the seven days before it, and one older that doesn't count.
        let logs = pair(daysAgo: 3) + pair(daysAgo: 8) + pair(daysAgo: 13) + pair(daysAgo: 20)
        #expect(Fixture.report(checks: [stove], logs: logs).trend == .down(percent: 50))
    }

    @Test func mostReCheckedIsTheTaskWithTheMostReLogs() throws {
        let door = Fixture.check("Door", order: 1, kind: .door)
        let logs = [
            Fixture.log(door, Fixture.date(hour: 7, minute: 0)),
            Fixture.log(door, Fixture.date(hour: 7, minute: 10)),
            Fixture.log(door, Fixture.date(hour: 7, minute: 20)),
            Fixture.log(stove, Fixture.date(hour: 8, minute: 0)),
            Fixture.log(stove, Fixture.date(hour: 8, minute: 10)),
        ]
        let most = try #require(Fixture.report(checks: [stove, door], logs: logs).mostRechecked)
        #expect(most == StatsReport.MostRechecked(name: "Door", kind: .door, count: 2))
    }

    @Test func aTieGoesToTheEarlierTask() {
        let door = Fixture.check("Door", order: 1)
        let logs = [
            Fixture.log(door, Fixture.date(hour: 7, minute: 0)),
            Fixture.log(door, Fixture.date(hour: 7, minute: 10)),
            Fixture.log(stove, Fixture.date(hour: 8, minute: 0)),
            Fixture.log(stove, Fixture.date(hour: 8, minute: 10)),
        ]
        #expect(Fixture.report(checks: [stove, door], logs: logs).mostRechecked?.name == "Stove off")
    }

    @Test func aSharedNameNamesItsCategory() {
        let bedtime = Fixture.category("Bedtime", .daily)
        let other = Fixture.check("Stove off", in: bedtime, order: 1)
        let logs = [Fixture.log(other, Fixture.date(hour: 8, minute: 0)), Fixture.log(other, Fixture.date(hour: 8, minute: 10))]
        let report = Fixture.report(categories: [Fixture.daily, bedtime], checks: [stove, other], logs: logs)
        #expect(report.mostRechecked?.name == "Stove off · Bedtime")
    }

    @Test func noReLogsMeansNoMostReChecked() {
        #expect(Fixture.report(checks: [stove], logs: [Fixture.log(stove, Fixture.date())]).mostRechecked == nil)
    }
}

struct StatsBreakdownTests {
    @Test func categoriesWithNothingDueInTheRangeAreLeftOut() {
        let monthly = Fixture.category("Monthly", .monthly(day: 15), order: 2)
        let friday = Fixture.category("Friday", .weekly(weekday: 6), order: 1)
        let door = Fixture.check("Door", order: 0)
        let bins = Fixture.check("Bins", in: friday, order: 1)
        let alarm = Fixture.check("Alarm", in: monthly, order: 2)
        let report = Fixture.report(
            categories: [monthly, friday, Fixture.daily],
            checks: [door, bins, alarm],
            logs: [Fixture.log(door, Fixture.date()), Fixture.log(bins, TestTime.date(2026, 10, 30, 7))]
        )
        #expect(report.categories.map(\.category.name) == ["Daily", "Friday"])
        #expect(report.categories.map(\.percent) == [14, 100])
    }

    @Test func aTaskInAnUnknownCategoryCountsAsDailys() {
        let lost = CheckRecord(id: UUID(), name: "Lost", kind: .other, order: 0, categoryID: UUID(), nudgesOnLeavingHome: false, createdAt: Fixture.longAgo)
        let report = Fixture.report(checks: [lost], logs: [Fixture.log(lost, Fixture.date())])
        #expect(report.bars.last?.percent == 100)
        #expect(report.categories.map(\.category.name) == ["Daily"])
    }

    @Test func sourcesGroupIntoMethodsInAFixedOrder() {
        let door = Fixture.check("Door")
        let sources: [LogSource] = [.app, .control, .actionButton, .actionButton, .siri, .shortcut, .notification, .lockScreenWidget]
        let logs = sources.enumerated().map { Fixture.log(door, Fixture.date(hour: 8 + $0.offset), source: $0.element) }
        let rows = Fixture.report(checks: [door], logs: logs).methods
        #expect(rows.map(\.method) == [.actionButton, .lockScreenWidget, .app, .siriAndShortcuts, .notification])
        #expect(rows.map(\.count) == [3, 1, 1, 2, 1])
        #expect(rows.map(\.percent) == [38, 13, 13, 25, 13])
    }

    @Test func aLogOutsideTheRangeIsNotCounted() {
        let door = Fixture.check("Door")
        let report = Fixture.report(checks: [door], logs: [
            Fixture.log(door, Fixture.date(daysAgo: 7), photo: "old.heic"),
            Fixture.log(door, Fixture.date(daysAgo: 6), photo: "new.heic"),
            Fixture.log(door, Fixture.date(hour: 9)),
        ])
        #expect(report.photosKept == 1)
        #expect(report.methods.map(\.count) == [2])
    }

    @Test func onlyLogsWithAPhotoCount() {
        let door = Fixture.check("Door")
        let logs = [Fixture.log(door, Fixture.date(hour: 8)), Fixture.log(door, Fixture.date(hour: 9), photo: "a.heic")]
        #expect(Fixture.report(checks: [door], logs: logs).photosKept == 1)
    }

    @Test(arguments: [(8, "8–9 AM"), (11, "11 AM–12 PM"), (12, "12–1 PM"), (23, "11 PM–12 AM"), (0, "12–1 AM")])
    func hourRanges(hour: Int, expected: String) {
        let text = StatsReport.hourRange(startingAt: hour, calendar: TestTime.calendar(), locale: Fixture.locale)
        #expect(text.plainSpaces == expected)
    }

    @Test func theBusiestHourHasTheMostLogsAndTiesGoEarlier() {
        let door = Fixture.check("Door")
        let busy = [Fixture.date(hour: 22), Fixture.date(daysAgo: 1, hour: 22, minute: 30), Fixture.date(hour: 8)].map { Fixture.log(door, $0) }
        #expect(Fixture.report(checks: [door], logs: busy).busiestHour?.plainSpaces == "10–11 PM")
        let tied = [Fixture.date(hour: 22), Fixture.date(hour: 8)].map { Fixture.log(door, $0) }
        #expect(Fixture.report(checks: [door], logs: tied).busiestHour?.plainSpaces == "8–9 AM")
    }

    @Test func withNoLogsInTheRangeThereIsNoBusiestHour() {
        let door = Fixture.check("Door")
        let report = Fixture.report(checks: [door], logs: [Fixture.log(door, Fixture.date(daysAgo: 30))])
        #expect(report.hasLogs)
        #expect(report.busiestHour == nil)
        #expect(report.methods.isEmpty)
    }

    @Test func anEmptyStoreHasNoLogs() {
        #expect(!Fixture.report(checks: []).hasLogs)
    }

    @Test func aLogOfARemovedTaskIsIgnored() {
        let door = Fixture.check("Door")
        let gone = Fixture.check("Gone")
        #expect(!Fixture.report(checks: [door], logs: [Fixture.log(gone, Fixture.date())]).hasLogs)
    }
}

@MainActor
struct StatsViewModelTests {
    private let clock = FixedTimeSource(Fixture.now)
    private let store: SwiftDataStore
    private let door: CheckRecord

    init() throws {
        store = SwiftDataStore(container: try .app(inMemory: true), timeSource: FixedTimeSource(TestTime.date(2026, 1, 1)))
        door = try store.addChecks([CheckDraft(name: "Front door locked")])[0]
    }

    private func makeViewModel() -> StatsViewModel {
        StatsViewModel(checkStore: store, logStore: store, days: FixedDays(), timeSource: clock, locale: Fixture.locale)
    }

    @Test func aReloadReadsTheStore() throws {
        _ = try store.log(door.id, source: .actionButton, at: Fixture.date(), photoFileName: nil)
        let viewModel = makeViewModel()
        #expect(viewModel.report == nil)
        viewModel.reload()
        #expect(viewModel.report?.hasLogs == true)
        #expect(viewModel.report?.bars.last?.percent == 100)
        #expect(viewModel.report?.methods.map(\.method) == [.actionButton])
    }

    @Test func theStoresCreationDateReachesTheReport() throws {
        // The check was created on Jan 1, so every day of this week is due.
        let viewModel = makeViewModel()
        viewModel.reload()
        #expect(viewModel.report?.bars.map(\.percent) == [0, 0, 0, 0, 0, 0, 0])
    }

    @Test func reportsAreKeptUntilTheNextReload() throws {
        let viewModel = makeViewModel()
        viewModel.reload()
        #expect(viewModel.report?.hasLogs == false)
        _ = try store.log(door.id, source: .app, at: Fixture.date(), photoFileName: nil)
        viewModel.selectRange(.month)
        viewModel.selectRange(.week)
        #expect(viewModel.report?.hasLogs == false)
        viewModel.reload()
        #expect(viewModel.report?.hasLogs == true)
    }

    @Test func theLastBarIsChosenUntilAnotherIs() throws {
        let viewModel = makeViewModel()
        viewModel.reload()
        #expect(viewModel.selectedBar?.detail == "Today")
        viewModel.selectBar("0")
        #expect(viewModel.selectedBar?.detail == "Tue, Oct 27")
        viewModel.selectBar("nope")
        #expect(viewModel.selectedBar?.detail == "Tue, Oct 27")
    }

    @Test func changingTheRangeGoesBackToTheLastBar() throws {
        let viewModel = makeViewModel()
        viewModel.reload()
        viewModel.selectBar("0")
        viewModel.selectRange(.year)
        #expect(viewModel.range == .year)
        #expect(viewModel.selectedBar?.detail == "Nov so far")
    }
}
