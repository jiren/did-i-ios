import Foundation

/// Which tasks are due on a day: those whose category's rule says so. A task in an unknown category counts as
/// Daily's.
nonisolated enum DueTasks {
    static func ids(on day: CalendarDay, categories: [CategoryRecord], checks: [CheckRecord], calendar: Calendar) -> Set<UUID> {
        let rules = Dictionary(categories.map { ($0.id, $0.rule) }, uniquingKeysWith: { first, _ in first })
        return Set(checks.filter { (rules[$0.categoryID] ?? .daily).isDue(on: day, calendar: calendar) }.map(\.id))
    }
}
