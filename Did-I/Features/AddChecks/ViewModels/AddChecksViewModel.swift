import Foundation
import Observation

/// The Add checks sheet (`Main.dc.html`): pick suggestions, add your own, then add them all at once.
@Observable
final class AddChecksViewModel {
    /// Suggestions not yet a check, then what the user typed this time.
    private(set) var chips: [String] = []
    private(set) var picked: Set<String> = []
    var customText = ""

    @ObservationIgnored private let store: any CheckStoring
    @ObservationIgnored private let changes: any ChangeNotifying
    /// Where the checks go; Daily when nil.
    @ObservationIgnored private let categoryID: UUID?
    @ObservationIgnored private var customs: [String] = []
    @ObservationIgnored private var existingNames: [String] = []

    init(store: any CheckStoring, changes: any ChangeNotifying, categoryID: UUID? = nil) {
        self.store = store
        self.changes = changes
        self.categoryID = categoryID
    }

    func load() {
        existingNames = (try? store.checks().map(\.name)) ?? []
        rebuildChips()
    }

    var pickedCount: Int { picked.count }

    var commitTitle: String {
        switch picked.count {
        case 0: String(localized: "Pick at least one")
        case 1: String(localized: "Add 1 check")
        default: String(localized: "Add \(picked.count) checks")
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
