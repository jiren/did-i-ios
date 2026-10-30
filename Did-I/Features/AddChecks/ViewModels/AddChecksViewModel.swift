import Foundation
import Observation

/// The Add sheet (`Main.dc.html`): pick a category, pick suggestions, add your own, then add them all at once.
@Observable
final class AddChecksViewModel {
    /// Suggestions not yet a check, then what the user typed this time.
    private(set) var chips: [String] = []
    private(set) var picked: Set<String> = []
    private(set) var categories: [CategoryRecord] = []
    /// Where the tasks go.
    private(set) var categoryID: UUID
    var customText = ""

    @ObservationIgnored private let store: any CheckStoring & CategoryStoring
    @ObservationIgnored private let changes: any ChangeNotifying
    @ObservationIgnored private var customs: [String] = []
    @ObservationIgnored private var checks: [CheckRecord] = []

    /// Opens on `categoryID`, or Daily when nil.
    init(store: any CheckStoring & CategoryStoring, changes: any ChangeNotifying, categoryID: UUID? = nil) {
        self.store = store
        self.changes = changes
        self.categoryID = categoryID ?? CategoryDefaults.dailyID
    }

    func load() {
        checks = (try? store.checks()) ?? []
        categories = (try? store.categories()) ?? []
        if !categories.contains(where: { $0.id == categoryID }) { categoryID = CategoryDefaults.dailyID }
        rebuildChips()
    }

    /// Suggestions follow the category: a name it already has is hidden.
    func selectCategory(_ id: UUID) {
        categoryID = id
        rebuildChips()
    }

    /// The names the chosen category already has.
    private var existingNames: [String] {
        checks.filter { $0.categoryID == categoryID }.map(\.name)
    }

    private var categoryName: String {
        categories.first { $0.id == categoryID }?.name ?? CategoryDefaults.dailyName
    }

    /// "Add to Bin night".
    var title: String { String(localized: "Add to \(categoryName)") }

    var pickedCount: Int { picked.count }

    var commitTitle: String {
        switch picked.count {
        case 0: String(localized: "Pick at least one")
        case 1: String(localized: "Add 1 task to \(categoryName)")
        default: String(localized: "Add \(picked.count) tasks to \(categoryName)")
        }
    }

    var canAddCustom: Bool { CheckName.cleaned(customText) != nil }

    func toggle(_ chip: String) {
        if picked.contains(chip) { picked.remove(chip) } else { picked.insert(chip) }
    }

    func isPicked(_ chip: String) -> Bool { picked.contains(chip) }

    /// Adds the typed name as a picked chip.
    func addCustom() {
        guard let name = CheckName.cleaned(customText) else { return }
        customText = ""
        if let existing = chips.first(where: { CheckName.key($0) == CheckName.key(name) }) {
            picked.insert(existing)
            return
        }
        guard !existingNames.contains(where: { CheckName.key($0) == CheckName.key(name) }) else { return }
        customs.append(name)
        picked.insert(name)
        rebuildChips()
    }

    /// Adds every picked chip, in the order shown. Returns whether anything was added.
    @discardableResult
    func commit() -> Bool {
        let names = chips.filter { picked.contains($0) }
        guard !names.isEmpty else { return false }
        do {
            try store.addChecks(names.map { CheckDraft(name: $0) }, to: categoryID)
            changes.didChange()
            return true
        } catch {
            return false
        }
    }

    private func rebuildChips() {
        let suggestions = CheckSuggestions.available(excluding: existingNames)
        let suggestionKeys = Set(suggestions.map(CheckName.key))
        chips = suggestions + customs.filter { !suggestionKeys.contains(CheckName.key($0)) }
    }
}
