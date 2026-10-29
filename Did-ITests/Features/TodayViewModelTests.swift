import Foundation
import Testing
@testable import Did_I

@MainActor
struct TodayViewModelTests {
    private let clock = FixedTimeSource(TestTime.date(2026, 10, 29, 10, 42))
    private let store: SwiftDataStore
    private let changes = ChangeSpy()
    private let viewModel: TodayViewModel
    private let checks: [CheckRecord]

    init() throws {
        store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
        checks = try store.addChecks(["Front door locked", "Pill taken", "Stove off", "Iron unplugged"].map { CheckDraft(name: $0) })
        viewModel = TodayViewModel(
            checkStore: store, logStore: store, days: FixedDays(), timeSource: clock, changes: changes,
            locale: Locale(identifier: "en_US"), toastDuration: .seconds(60)
        )
    }

    @Test func aNewDayShowsEveryCheckUndone() {
        viewModel.reload()
        #expect(viewModel.dateText == "Thursday, Oct 29")
        #expect(viewModel.tiles.map(\.content.isDone) == [false, false, false, false])
        #expect(viewModel.tiles.first?.content.timeText == "Tap to log")
        #expect(viewModel.summary.summaryText == "4 left to check")
        #expect(viewModel.tiles.map(\.content.swatch) == [.violet, .sun, .coral, .mint])
    }

    @Test func yesterdaysLogDoesNotCountToday() throws {
        _ = try store.log(checks[0].id, source: .app, at: TestTime.date(2026, 10, 28, 22, 58), photoFileName: nil)
        viewModel.reload()
        #expect(viewModel.tiles[0].content.isDone == false)
        #expect(viewModel.recent.first?.meta.plainSpaces == "Yesterday, 10:58 PM")
    }

    @Test func loggingFillsTheTileAndShowsTheToast() {
        viewModel.reload()
        viewModel.log(checks[0].id)
        let tile = viewModel.tiles[0].content
        #expect(tile.isDone)
        #expect(tile.timeText.plainSpaces == "10:42 AM")
        #expect(tile.detailText == "Just now")
        #expect(viewModel.toast?.message == "Logged · Front door locked")
        #expect(viewModel.summary.progressText == "1 of 4 today")
        #expect(viewModel.recent.map(\.title) == ["Front door locked"])
        #expect(viewModel.logCount == 1)
        #expect(changes.count == 1)
    }

    @Test func timesMoveOnWithoutReading() {
        viewModel.reload()
        viewModel.log(checks[1].id)
        clock.now = clock.now.addingTimeInterval(2 * 3600 + 27 * 60)
        viewModel.rebuild()
        #expect(viewModel.tiles[1].content.detailText == "2h 27m ago")
    }

    @Test func undoRemovesTheLog() {
        viewModel.reload()
        viewModel.log(checks[0].id)
        viewModel.undo()
        #expect(viewModel.toast == nil)
        #expect(viewModel.tiles[0].content.isDone == false)
        #expect(viewModel.recent.isEmpty)
        #expect(changes.count == 2)
    }

    @Test func allClearOnceEveryCheckIsLogged() {
        viewModel.reload()
        checks.forEach { viewModel.log($0.id) }
        #expect(viewModel.summary.summaryText == "All clear. Nothing to recheck.")
        #expect(viewModel.recent.count == 3)
    }

    @Test func aPhotoLogSaysSo() {
        viewModel.reload()
        viewModel.log(checks[0].id, photoFileName: "door.heic")
        #expect(viewModel.toast?.message == "Photo saved · Front door locked")
        #expect(viewModel.tiles[0].content.detailText == "Just now · photo")
        #expect(viewModel.tiles[0].content.photoButtonLabel == "Retake photo for Front door locked")
    }

    @Test func theToastGoesAwayOnItsOwn() async throws {
        let quick = TodayViewModel(
            checkStore: store, logStore: store, days: FixedDays(), timeSource: clock, changes: changes,
            locale: Locale(identifier: "en_US"), toastDuration: .milliseconds(10)
        )
        quick.reload()
        quick.log(checks[0].id)
        try await Task.sleep(for: .milliseconds(200))
        #expect(quick.toast == nil)
    }
}
