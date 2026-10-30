import Foundation
import Observation

struct HistoryRow: Identifiable, Equatable {
    let id: UUID
    let checkID: UUID
    var checkName: String
    var kind: CheckKind
    var swatch: TileSwatch
    /// "8:42 AM"
    var time: String
    /// "Action Button · photo"
    var source: String
    var hasPhoto: Bool
}

struct HistorySection: Identifiable, Equatable {
    /// The day's start.
    let id: Date
    var title: String
    var rows: [HistoryRow]
}

struct HistoryFilter: Identifiable, Equatable {
    let id: UUID?
    var title: String
}

/// Every log, grouped by day, optionally for one category or one check.
@Observable
final class HistoryViewModel {
    static let limit = 1000

    private(set) var sections: [HistorySection] = []
    private(set) var filters: [HistoryFilter] = []
    private(set) var selectedCheckID: UUID?
    /// Every category, for the category chips (shown once there's more than Daily).
    private(set) var categories: [CategoryRecord] = []
    private(set) var selectedCategoryID: UUID?
    private(set) var errorMessage: String?

    @ObservationIgnored private let checkStore: any CheckStoring & CategoryStoring
    @ObservationIgnored private let logStore: any LogStoring
    @ObservationIgnored private let days: any DayBoundaryProviding
    @ObservationIgnored private let timeSource: any TimeSource
    @ObservationIgnored private let changes: any ChangeNotifying
    @ObservationIgnored private let photos: (any PhotoFileRemoving)?
    @ObservationIgnored private let locale: Locale

    init(
        checkStore: any CheckStoring & CategoryStoring,
        logStore: any LogStoring,
        days: any DayBoundaryProviding,
        timeSource: any TimeSource,
        changes: any ChangeNotifying,
        photos: (any PhotoFileRemoving)?,
        selectedCheckID: UUID? = nil,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.checkStore = checkStore
        self.logStore = logStore
        self.days = days
        self.timeSource = timeSource
        self.changes = changes
        self.photos = photos
        self.selectedCheckID = selectedCheckID
        self.locale = locale
    }

    var isEmpty: Bool { sections.isEmpty }

    func select(_ checkID: UUID?) {
        selectedCheckID = checkID
        reload()
    }

    /// Nil shows every category; choosing one clears a check from another.
    func selectCategory(_ categoryID: UUID?) {
        selectedCategoryID = categoryID
        reload()
    }

    func reload() {
        do {
            let checks = try checkStore.checks()
            categories = try checkStore.categories()
            if let selected = selectedCategoryID, !categories.contains(where: { $0.id == selected }) { selectedCategoryID = nil }
            let shown = selectedCategoryID.map { id in checks.filter { $0.categoryID == id } } ?? checks
            if let selected = selectedCheckID, !shown.contains(where: { $0.id == selected }) { selectedCheckID = nil }
            let titles = CheckLabels.titles(for: checks, categories: categories)
            filters = [HistoryFilter(id: nil, title: String(localized: "All"))]
                + shown.map { HistoryFilter(id: $0.id, title: titles[$0.id] ?? $0.name) }
            var logs = try logStore.logs(for: selectedCheckID, limit: Self.limit)
            if selectedCheckID == nil, selectedCategoryID != nil {
                let ids = Set(shown.map(\.id))
                logs = logs.filter { ids.contains($0.checkID) }
            }
            sections = Self.group(logs, checks: checks, boundary: days.dayBoundary, now: timeSource.now, locale: locale)
            errorMessage = nil
        } catch {
            errorMessage = String(localized: "Couldn’t read your history.")
        }
    }

    func delete(_ logID: UUID) {
        do {
            if let photo = try logStore.deleteLog(logID) { photos?.removePhotos(named: [photo]) }
            changes.didChange()
            reload()
        } catch {
            errorMessage = String(localized: "Couldn’t delete that log.")
        }
    }

    static func group(
        _ logs: [LogRecord], checks: [CheckRecord], boundary: DayBoundary, now: Date, locale: Locale
    ) -> [HistorySection] {
        let time = RelativeTime(boundary: boundary, locale: locale)
        let positions = Dictionary(uniqueKeysWithValues: checks.enumerated().map { ($1.id, ($0, $1)) })
        var sections: [HistorySection] = []
        for log in logs {
            guard let (position, check) = positions[log.checkID] else { continue }
            let dayStart = boundary.day(containing: log.date).start
            let row = HistoryRow(
                id: log.id, checkID: check.id, checkName: check.name, kind: check.kind,
                swatch: TileSwatch.at(position: position), time: time.clockTime(log.date),
                source: log.source.label(hasPhoto: log.hasPhoto), hasPhoto: log.hasPhoto
            )
            if sections.last?.id == dayStart {
                sections[sections.count - 1].rows.append(row)
            } else {
                sections.append(HistorySection(id: dayStart, title: time.dayName(log.date, now: now), rows: [row]))
            }
        }
        return sections
    }
}
