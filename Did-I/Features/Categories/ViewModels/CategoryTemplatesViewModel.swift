import Foundation
import Observation

/// The template gallery at the start of New category: each template, its repeat and task count, and whether a
/// category already has its name.
@Observable
final class CategoryTemplatesViewModel {
    struct Item: Identifiable, Equatable {
        var template: CategoryTemplate
        /// "Every day · 5 tasks".
        var detail: String
        /// A category already has this name; picking it opens as "Bin night 2".
        var isAdded: Bool

        var id: String { template.id }
    }

    private(set) var items: [Item] = []

    @ObservationIgnored private let store: any CategoryStoring
    @ObservationIgnored private let days: any DayBoundaryProviding
    @ObservationIgnored private let timeSource: any TimeSource
    @ObservationIgnored private let locale: Locale

    init(store: any CategoryStoring, days: any DayBoundaryProviding, timeSource: any TimeSource, locale: Locale = .autoupdatingCurrent) {
        self.store = store
        self.days = days
        self.timeSource = timeSource
        self.locale = locale
    }

    func load() {
        let names = Set(((try? store.categories()) ?? []).map { CheckName.key($0.name) })
        let boundary = days.dayBoundary
        let today = boundary.calendarDay(containing: timeSource.now)
        items = CategoryTemplates.all.map { template in
            let rule = template.rule(today: today, calendar: boundary.calendar).label(calendar: boundary.calendar, locale: locale)
            let count = template.tasks.count
            let tasks = count == 1 ? String(localized: "1 task") : String(localized: "\(count) tasks")
            return Item(
                template: template,
                detail: String(localized: "\(rule) · \(tasks)"),
                isAdded: names.contains(CheckName.key(template.name))
            )
        }
    }
}
