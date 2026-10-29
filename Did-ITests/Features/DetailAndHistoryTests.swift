import Foundation
import Testing
@testable import Did_I

@MainActor
struct DetailViewModelTests {
    private let clock = FixedTimeSource(TestTime.date(2026, 10, 29, 10, 51))
    private let store: SwiftDataStore
    private let changes = ChangeSpy()
    private let door: CheckRecord

    init() throws {
        store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
        door = try store.addChecks([CheckDraft(name: "Front door locked"), CheckDraft(name: "Pill taken")])[0]
    }

    private func makeViewModel(_ id: UUID? = nil) -> DetailViewModel {
        DetailViewModel(
            checkID: id ?? door.id, checkStore: store, logStore: store, days: FixedDays(), timeSource: clock,
            changes: changes, editor: CheckEditor(store: store, changes: changes, photos: nil), photos: nil,
            locale: Locale(identifier: "en_US")
        )
    }

    @Test func theHeaderReadsTheLatestLog() throws {
        _ = try store.log(door.id, source: .lockScreenWidget, at: TestTime.date(2026, 10, 28, 22, 58), photoFileName: nil)
        _ = try store.log(door.id, source: .actionButton, at: TestTime.date(2026, 10, 29, 8, 42), photoFileName: "p.heic")
        let viewModel = makeViewModel()
        viewModel.reload()
        #expect(viewModel.headline.plainSpaces == "Locked at 8:42 AM")
        #expect(viewModel.subheadline == "Today · 2h 9m ago")
        #expect(viewModel.timeline.map(\.subtitle) == ["Action Button · photo", "Lock Screen widget"])
        #expect(viewModel.timeline.last?.title.plainSpaces == "Yesterday, 10:58 PM")
        #expect(viewModel.countText == "2 logs")
    }

    @Test func aNewCheckIsNotLoggedYet() {
        let viewModel = makeViewModel()
        viewModel.reload()
        #expect(viewModel.headline == "Not logged yet")
        #expect(viewModel.countText == "0 logs")
    }

    @Test func logAgainAndUndo() throws {
        let viewModel = makeViewModel()
        viewModel.reload()
        viewModel.logAgain()
        #expect(viewModel.countText == "1 log")
        #expect(viewModel.timeline.first?.subtitle == "In the app")
        viewModel.undo()
        #expect(viewModel.countText == "0 logs")
    }

    @Test func theNudgeSwitchIsStored() throws {
        let viewModel = makeViewModel()
        viewModel.reload()
        viewModel.setNudgesOnLeavingHome(true)
        #expect(try store.check(id: door.id)?.nudgesOnLeavingHome == true)
    }

    @Test func removingMarksItRemoved() throws {
        let viewModel = makeViewModel()
        viewModel.reload()
        viewModel.remove()
        #expect(viewModel.isRemoved)
        #expect(try store.check(id: door.id) == nil)
    }

    @Test func theHeaderTakesTheTilesColour() throws {
        let pill = try store.checks()[1]
        let viewModel = makeViewModel(pill.id)
        viewModel.reload()
        #expect(viewModel.swatch == .sun)
        #expect(viewModel.headline == "Not logged yet")
    }
}

@MainActor
struct HistoryViewModelTests {
    private let clock = FixedTimeSource(TestTime.date(2026, 10, 29, 10, 51))
    private let store: SwiftDataStore
    private let changes = ChangeSpy()
    private let checks: [CheckRecord]

    init() throws {
        store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
        checks = try store.addChecks([CheckDraft(name: "Front door locked"), CheckDraft(name: "Pill taken")])
        _ = try store.log(checks[0].id, source: .app, at: TestTime.date(2026, 10, 27, 8, 37), photoFileName: nil)
        _ = try store.log(checks[1].id, source: .siri, at: TestTime.date(2026, 10, 28, 22, 58), photoFileName: nil)
        _ = try store.log(checks[0].id, source: .actionButton, at: TestTime.date(2026, 10, 29, 8, 42), photoFileName: "p.heic")
    }

    private func makeViewModel() -> HistoryViewModel {
        HistoryViewModel(
            checkStore: store, logStore: store, days: FixedDays(), timeSource: clock, changes: changes, photos: nil,
            locale: Locale(identifier: "en_US")
        )
    }

    @Test func groupsByDayNewestFirst() {
        let viewModel = makeViewModel()
        viewModel.reload()
        #expect(viewModel.sections.map(\.title) == ["Today", "Yesterday", "Tue, Oct 27"])
        #expect(viewModel.sections[0].rows.first?.source == "Action Button · photo")
        #expect(viewModel.sections[1].rows.first?.swatch == .sun)
        #expect(viewModel.filters.map(\.title) == ["All", "Front door locked", "Pill taken"])
    }

    @Test func filtersByCheck() {
        let viewModel = makeViewModel()
        viewModel.select(checks[1].id)
        #expect(viewModel.sections.flatMap(\.rows).map(\.checkName) == ["Pill taken"])
    }

    @Test func deletesALog() throws {
        let photos = PhotoRemovalSpy()
        let viewModel = HistoryViewModel(
            checkStore: store, logStore: store, days: FixedDays(), timeSource: clock, changes: changes, photos: photos,
            locale: Locale(identifier: "en_US")
        )
        viewModel.reload()
        let row = try #require(viewModel.sections.first?.rows.first)
        viewModel.delete(row.id)
        #expect(photos.removed == ["p.heic"])
        #expect(viewModel.sections.map(\.title) == ["Yesterday", "Tue, Oct 27"])
        #expect(changes.count == 1)
    }
}
