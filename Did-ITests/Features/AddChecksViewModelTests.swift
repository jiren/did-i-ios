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
    }

    @Test func existingChecksAreHidden() throws {
        try store.addChecks([CheckDraft(name: "Pill taken")])
        viewModel.load()
        #expect(!viewModel.chips.contains("Pill taken"))
    }

    @Test(arguments: [(1, "Add 1 check"), (3, "Add 3 checks")])
    func commitTitle(count: Int, title: String) {
        viewModel.load()
        viewModel.chips.prefix(count).forEach(viewModel.toggle)
        #expect(viewModel.commitTitle == title)
    }

    @Test func customChecksArePickedAndAddedInOrder() throws {
        viewModel.load()
        viewModel.toggle("Windows closed")
        viewModel.customText = "  Cat fed "
        viewModel.addCustom()
        #expect(viewModel.customText.isEmpty)
        #expect(viewModel.chips.last == "Cat fed")
        #expect(viewModel.isPicked("Cat fed"))
        #expect(viewModel.commit())
        #expect(try store.checks().map(\.name) == ["Windows closed", "Cat fed"])
        #expect(changes.count == 1)
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
