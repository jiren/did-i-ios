import Foundation
import Observation

/// Settings › Categories: every category to edit, reorder or delete, with one-offs whose date has gone under Past.
@Observable
final class CategoriesSettingsViewModel {
    struct Row: Identifiable, Equatable {
        var category: CategoryRecord
        /// "Every Friday · 2 tasks".
        var detail: String

        var id: UUID { category.id }
    }

    private(set) var current: [Row] = []
    private(set) var past: [Row] = []
    var deletion: CategoryDeletionRequest?
    private(set) var errorMessage: String?

    @ObservationIgnored private let store: any CheckStoring & CategoryStoring
    @ObservationIgnored private let editor: CategoryEditor
    @ObservationIgnored private let days: any DayBoundaryProviding
    @ObservationIgnored private let timeSource: any TimeSource
    @ObservationIgnored private let locale: Locale

    init(
        store: any CheckStoring & CategoryStoring,
        editor: CategoryEditor,
        days: any DayBoundaryProviding,
        timeSource: any TimeSource,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.store = store
        self.editor = editor
        self.days = days
        self.timeSource = timeSource
        self.locale = locale
    }

    func load() {
        let boundary = days.dayBoundary
        let today = boundary.calendarDay(containing: timeSource.now)
        let categories = (try? store.categories()) ?? []
        let checks = (try? store.checks()) ?? []
        let rows = categories.map { category in
            let count = checks.filter { $0.categoryID == category.id }.count
            let tasks = count == 1 ? String(localized: "1 task") : String(localized: "\(count) tasks")
            let rule = category.rule.label(calendar: boundary.calendar, locale: locale)
            return Row(category: category, detail: String(localized: "\(rule) · \(tasks)"))
        }
        current = rows.filter { !$0.category.rule.isPast(before: today) }
        past = rows.filter { $0.category.rule.isPast(before: today) }
    }

    /// Drag to reorder the current categories; past ones keep their place after them.
    func move(from source: IndexSet, to destination: Int) {
        let ids = current.map(\.id)
        let moving = source.map { ids[$0] }
        let before = ids[..<min(destination, ids.count)].filter { !moving.contains($0) }
        let after = ids[min(destination, ids.count)...].filter { !moving.contains($0) }
        do {
            try editor.reorder(before + moving + after + past.map(\.id))
            load()
        } catch {
            errorMessage = String(localized: "Couldn’t reorder your categories.")
        }
    }

    func askToDelete(_ id: UUID) {
        deletion = editor.deletionRequest(for: id)
    }

    func delete(_ id: UUID, _ choice: CategoryDeletion) {
        do {
            try editor.delete(id, choice)
            load()
        } catch {
            errorMessage = String(localized: "Couldn’t delete that category.")
        }
    }
}
