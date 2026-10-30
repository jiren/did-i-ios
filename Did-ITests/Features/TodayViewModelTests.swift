import Foundation
import Testing
@testable import Did_I

/// Thursday, Oct 29, 2026 at 10:42 AM: Daily's four tasks, and Bin night due on Fridays.
@MainActor
struct TodayViewModelTests {
    private let clock = FixedTimeSource(TestTime.date(2026, 10, 29, 10, 42))
    private let store: SwiftDataStore
    private let changes = ChangeSpy()
    private let viewModel: TodayViewModel
    private let checks: [CheckRecord]
    private let bins: CategoryRecord
    private static let thursday = CalendarDay(year: 2026, month: 10, day: 29)
    private static let friday = CalendarDay(year: 2026, month: 10, day: 30)

    init() throws {
        store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
        checks = try store.addChecks(["Front door locked", "Pill taken", "Stove off", "Iron unplugged"].map { CheckDraft(name: $0) })
        bins = try store.addCategory(
            CategoryDraft(name: "Bin night", icon: .bin, colour: .mint, rule: .weekly(weekday: 6)),
            tasks: [CheckDraft(name: "Bins out"), CheckDraft(name: "Recycling out")]
        )
        viewModel = Self.makeViewModel(store: store, clock: clock, changes: changes, toastDuration: .seconds(60))
    }

    private static func makeViewModel(
        store: SwiftDataStore, clock: FixedTimeSource, changes: ChangeSpy, toastDuration: Duration
    ) -> TodayViewModel {
        TodayViewModel(
            checkStore: store, logStore: store, days: FixedDays(), timeSource: clock, changes: changes,
            editor: CheckEditor(store: store, changes: changes, photos: nil), locale: Locale(identifier: "en_US"),
            toastDuration: toastDuration
        )
    }

    private var tiles: [TodayTile] { viewModel.sections.flatMap(\.tiles) }

    @Test func aNewDayShowsTodaysDueTasksUndone() {
        viewModel.reload()
        #expect(viewModel.dateText == "Today · Thu, Oct 29")
        #expect(viewModel.isToday)
        #expect(!viewModel.isEmpty)
        #expect(viewModel.sections.map(\.category.name) == ["Daily"])
        #expect(tiles.map(\.content.state) == [.toLog, .toLog, .toLog, .toLog])
        #expect(tiles.map(\.content.swatch) == [.violet, .sun, .coral, .mint])
        #expect(tiles[0].content.accessibilityLabel == "Front door locked, not logged — tap to log")
        #expect(viewModel.progress.main == "0 of 4 done")
        #expect(viewModel.progress.pill == .left(4))
        #expect(viewModel.categories.map(\.name) == ["Daily", "Bin night"])
        #expect(viewModel.strip.count == 7)
    }

    @Test func anEmptyStoreShowsTheEmptyState() throws {
        try store.deleteEverything()
        viewModel.reload()
        #expect(viewModel.isEmpty)
    }

    @Test func yesterdaysLogDoesNotCountToday() throws {
        _ = try store.log(checks[0].id, source: .app, at: TestTime.date(2026, 10, 28, 22, 58), photoFileName: nil)
        viewModel.reload()
        #expect(tiles[0].content.isDone == false)
    }

    @Test func loggingFillsTheTileAndShowsTheToast() {
        viewModel.reload()
        viewModel.log(checks[0].id)
        let tile = tiles[0].content
        #expect(tile.isDone)
        #expect(tile.statusText.plainSpaces == "10:42 AM")
        #expect(tile.accessibilityLabel.plainSpaces == "Front door locked, logged 10:42 AM — tap to log again")
        #expect(viewModel.toast?.message == "Logged · Front door locked")
        #expect(viewModel.progress.main == "1 of 4 done")
        #expect(viewModel.sections[0].progressText == "1/4")
        #expect(viewModel.todayProgress == 0.25)
        #expect(viewModel.ringAccessibilityLabel == "Today: 1 of 4 checked")
        #expect(viewModel.logCount == 1)
        #expect(changes.count == 1)
    }

    @Test func undoRemovesTheLog() {
        viewModel.reload()
        viewModel.log(checks[0].id)
        viewModel.undo()
        #expect(viewModel.toast == nil)
        #expect(tiles[0].content.isDone == false)
        #expect(changes.count == 2)
    }

    @Test func allClearOnceEveryDueTaskIsLogged() {
        viewModel.reload()
        checks.forEach { viewModel.log($0.id) }
        #expect(viewModel.progress.pill == .allClear)
        #expect(viewModel.todayProgress == 1)
    }

    @Test func aPhotoLogSaysSo() {
        viewModel.reload()
        viewModel.log(checks[0].id, photoFileName: "door.heic")
        #expect(viewModel.toast?.message == "Photo saved · Front door locked")
        #expect(tiles[0].content.hasPhoto)
        #expect(tiles[0].content.photoButtonLabel == "Retake photo for Front door locked")
    }

    @Test func aLaterDayIsUpcomingAndCantBeLogged() {
        viewModel.reload()
        viewModel.select(Self.friday)
        #expect(!viewModel.isToday)
        #expect(viewModel.dateText == "Fri, Oct 30")
        #expect(viewModel.sections.map(\.category.name) == ["Daily", "Bin night"])
        #expect(tiles.allSatisfy { $0.content.state == .upcoming })
        #expect(tiles[4].content.accessibilityLabel == "Bins out, upcoming on Fri, Oct 30")
        #expect(viewModel.progress.main == "6 checks planned")

        viewModel.log(checks[0].id)
        #expect(viewModel.toast == nil)
        #expect(viewModel.logCount == 0)
        #expect(viewModel.todayProgress == 0)
    }

    @Test func aFilterShowsOneCategory() {
        viewModel.reload()
        viewModel.selectFilter(bins.id)
        #expect(viewModel.sections.isEmpty)
        #expect(viewModel.nothingDueText == "Bin night isn’t due on Thu, Oct 29. Check Coming up below.")
        #expect(viewModel.addTarget == bins.id)
        viewModel.select(Self.friday)
        #expect(viewModel.sections.map(\.category.name) == ["Bin night"])
        viewModel.selectFilter(nil)
        #expect(viewModel.sections.count == 2)
        #expect(viewModel.addTarget == nil)
    }

    @Test func comingUpOpensItsDay() throws {
        viewModel.reload()
        let upcoming = try #require(viewModel.comingUp.first)
        #expect(upcoming.category.name == "Bin night")
        #expect(upcoming.when == "Tomorrow")
        #expect(upcoming.detail == "2 checks · Every Friday")
        viewModel.selectFilter(CategoryDefaults.dailyID)
        viewModel.open(upcoming)
        #expect(viewModel.dateText == "Fri, Oct 30")
        #expect(viewModel.filterID == nil)
    }

    @Test func theSelectedDayGoesBackToTodayWhenTheDayChanges() {
        viewModel.reload()
        viewModel.select(CalendarDay(year: 2026, month: 11, day: 2))
        clock.now = TestTime.date(2026, 10, 30, 7)
        viewModel.rebuild()
        #expect(viewModel.isToday)
        #expect(viewModel.dateText == "Today · Fri, Oct 30")
        #expect(viewModel.sections.map(\.category.name) == ["Daily", "Bin night"])
    }

    @Test func aNewDayStartsUndone() throws {
        viewModel.reload()
        viewModel.log(checks[0].id)
        clock.now = TestTime.date(2026, 10, 30, 7)
        viewModel.rebuild()
        #expect(tiles[0].content.isDone == false)
    }

    @Test func movingStaysWithinTheCategory() {
        viewModel.reload()
        #expect(!viewModel.canMove(checks[0].id, by: -1))
        #expect(!viewModel.canMove(checks[3].id, by: 1))
        viewModel.move(checks[0].id, by: 1)
        #expect(viewModel.sections[0].tiles.map(\.id) == [checks[1].id, checks[0].id, checks[2].id, checks[3].id])
        viewModel.move(checks[3].id, to: checks[1].id)
        #expect(viewModel.sections[0].tiles.first?.id == checks[3].id)
        viewModel.rename(checks[3].id, to: "Iron off")
        #expect(viewModel.sections[0].tiles.first?.content.name == "Iron off")
    }

    @Test func aTileCantBeDroppedIntoAnotherCategory() throws {
        viewModel.reload()
        viewModel.select(Self.friday)
        let binsOut = try #require(viewModel.sections[1].tiles.first?.id)
        viewModel.move(binsOut, to: checks[0].id)
        #expect(viewModel.sections[0].tiles.map(\.id) == checks.map(\.id))
    }

    @Test func removingACheckDropsItsToast() throws {
        viewModel.reload()
        viewModel.log(checks[2].id)
        #expect(viewModel.removeRequest(for: checks[2].id) == .remove(checks[2], logCount: 1))
        viewModel.remove(checks[2].id)
        #expect(viewModel.toast == nil)
        #expect(tiles.count == 3)
    }

    @Test func theToastGoesAwayOnItsOwn() async throws {
        let quick = Self.makeViewModel(store: store, clock: clock, changes: changes, toastDuration: .milliseconds(10))
        quick.reload()
        quick.log(checks[0].id)
        try await Task.sleep(for: .milliseconds(200))
        #expect(quick.toast == nil)
    }
}
