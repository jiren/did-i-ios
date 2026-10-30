import Foundation
import Testing
@testable import Did_I

@MainActor
struct AddChecksViewModelTests {
    private let store: SwiftDataStore
    private let changes = ChangeSpy()
    private let viewModel: AddChecksViewModel

    init() throws {
        store = SwiftDataStore(container: try .app(inMemory: true))
        viewModel = AddChecksViewModel(store: store, changes: changes)
    }

    @Test func aNewInstallLeadsWithTheDesignsChecks() {
        viewModel.load()
        #expect(Array(viewModel.chips.prefix(4)) == ["Front door locked", "Pill taken", "Stove off", "Iron unplugged"])
        #expect(viewModel.commitTitle == "Pick at least one")
        #expect(viewModel.title == "Add to Daily")
        #expect(viewModel.categoryID == CategoryDefaults.dailyID)
    }

    @Test func existingChecksAreHidden() throws {
        try store.addChecks([CheckDraft(name: "Pill taken")])
        viewModel.load()
        #expect(!viewModel.chips.contains("Pill taken"))
    }

    @Test(arguments: [(1, "Add 1 task to Daily"), (3, "Add 3 tasks to Daily")])
    func commitTitle(count: Int, title: String) {
        viewModel.load()
        viewModel.chips.prefix(count).forEach(viewModel.toggle)
        #expect(viewModel.commitTitle == title)
    }

    @Test func customChecksArePickedAndAddedInOrder() throws {
        viewModel.load()
        viewModel.toggle("Car locked")
        viewModel.customText = "  Cat fed "
        viewModel.addCustom()
        #expect(viewModel.customText.isEmpty)
        #expect(viewModel.chips.last == "Cat fed")
        #expect(viewModel.isPicked("Cat fed"))
        #expect(viewModel.commit())
        #expect(try store.checks().map(\.name) == ["Car locked", "Cat fed"])
        #expect(changes.count == 1)
    }

    @Test func addsToTheChosenCategory() throws {
        let bins = try store.addCategory(CategoryDraft(name: "Bin night", rule: .weekly(weekday: 6)), tasks: [])
        let sheet = AddChecksViewModel(store: store, changes: changes, categoryID: bins.id)
        sheet.load()
        #expect(sheet.title == "Add to Bin night")
        #expect(sheet.categories.map(\.name) == ["Daily", "Bin night"])
        sheet.toggle("Keys packed")
        #expect(sheet.commitTitle == "Add 1 task to Bin night")
        sheet.selectCategory(CategoryDefaults.dailyID)
        #expect(sheet.commitTitle == "Add 1 task to Daily")
        sheet.selectCategory(bins.id)
        #expect(sheet.commit())
        #expect(try store.checks().first?.categoryID == bins.id)
    }

    @Test func suggestionsFollowTheChosenCategory() throws {
        try store.addChecks([CheckDraft(name: "Car locked")])
        let bins = try store.addCategory(CategoryDraft(name: "Bin night"), tasks: [])
        viewModel.load()
        #expect(!viewModel.chips.contains("Car locked"))
        viewModel.selectCategory(bins.id)
        #expect(viewModel.chips.contains("Car locked"))
        viewModel.toggle("Car locked")
        #expect(viewModel.commit())
        #expect(try store.checks().filter { $0.name == "Car locked" }.count == 2)
    }

    @Test func anUnknownCategoryFallsBackToDaily() {
        let sheet = AddChecksViewModel(store: store, changes: changes, categoryID: UUID())
        sheet.load()
        #expect(sheet.categoryID == CategoryDefaults.dailyID)
    }

    @Test func typingASuggestionPicksIt() {
        viewModel.load()
        viewModel.customText = "stove OFF"
        viewModel.addCustom()
        #expect(viewModel.isPicked("Stove off"))
        #expect(viewModel.chips.filter { $0.lowercased() == "stove off" }.count == 1)
    }

    @Test func nothingPickedAddsNothing() {
        viewModel.load()
        #expect(!viewModel.commit())
        #expect(changes.count == 0)
    }
}
