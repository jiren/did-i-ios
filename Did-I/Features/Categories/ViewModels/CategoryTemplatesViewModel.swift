import Foundation
import Observation

/// The template gallery at the start of New category: each template, its repeat and task count, and whether a
/// category already has its name.
@Observable
final class CategoryTemplatesViewModel {
    typealias Item = CategoryTemplateItem

    struct Section: Identifiable, Equatable {
        let id: String
        let title: String
        var items: [Item]
    }

    private(set) var sections: [Section] = []

    var items: [Item] { sections.flatMap(\.items) }

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
        sections = CategoryTemplates.groups.map { group in
            Section(id: group.id, title: group.title, items: group.templates.map {
                CategoryTemplateItem($0, usedNames: names, today: today, calendar: boundary.calendar, locale: locale)
            })
        }
    }
}
