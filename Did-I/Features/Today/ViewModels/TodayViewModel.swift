import Foundation
import Observation
import UIKit

/// Provides the day's boundary; `AppSettings` in the app, a fixed one in tests.
protocol DayBoundaryProviding: AnyObject {
    var dayBoundary: DayBoundary { get }
}

extension AppSettings: DayBoundaryProviding, TodayLayoutStoring {}

/// Today as a calendar (`Main.dc.html`): a day from the 7-day strip, a category filter, the due categories with
/// their tasks (collapsible, as tiles or rows) and the progress bar. Only today's tasks can be logged.
@Observable
final class TodayViewModel {
    /// "Today" or "Sat".
    private(set) var dayTitle = ""
    /// "Fri, Oct 30" or "Oct 31".
    private(set) var daySub = ""
    private(set) var strip: [DayAgenda.StripDay] = []
    /// Every category, for the filter chips.
    private(set) var categories: [CategoryRecord] = []
    /// The category shown alone, or nil for All.
    private(set) var filterID: UUID?
    private(set) var progress = DayAgenda.Progress(scope: "", main: "", pill: .free, segments: [])
    private(set) var sections: [TodaySection] = []
    /// "No tasks scheduled for Sat, Oct 31." when nothing is due.
    private(set) var nothingDueText: String?
    /// Tiles or rows; kept in settings.
    private(set) var layout: TodayLayout = .grid
    private(set) var isToday = true
    /// Today's due tasks done, 0 to 1, for the tab bar's ring.
    private(set) var todayProgress = 0.0
    /// "Today: 4 of 8 checked".
    private(set) var ringAccessibilityLabel = ""
    private(set) var toast: LogToast?
    private(set) var errorMessage: String?
    /// Bumped on each log, to play the success haptic.
    private(set) var logCount = 0

    /// No checks at all: the empty state instead of the calendar.
    private(set) var isEmpty = false

    @ObservationIgnored private let checkStore: any CheckStoring & CategoryStoring
    @ObservationIgnored private let logStore: any LogStoring
    @ObservationIgnored private let days: any DayBoundaryProviding
    @ObservationIgnored private let timeSource: any TimeSource
    @ObservationIgnored private let changes: any ChangeNotifying
    @ObservationIgnored private let editor: CheckEditor
    @ObservationIgnored private let categoryEditor: CategoryEditor
    @ObservationIgnored private let photos: PhotoStore?
    @ObservationIgnored private let layoutStore: any TodayLayoutStoring
    @ObservationIgnored private let locale: Locale
    @ObservationIgnored private let toastDuration: Duration

    @ObservationIgnored private var checks: [CheckRecord] = []
    /// Logs from the day they were read for (`logsDay`).
    @ObservationIgnored private var todaysLogs: [LogRecord] = []
    @ObservationIgnored private var logsDay: CalendarDay?
    /// The day picked in the strip; nil means today, and it goes back to nil when the day changes.
    @ObservationIgnored private var selectedDay: CalendarDay?
    @ObservationIgnored private var agendaToday: CalendarDay?
    /// Sections opened or closed by hand, until the day changes; others are closed when all done.
    @ObservationIgnored private var expandedOverrides: [UUID: Bool] = [:]

    init(
        checkStore: any CheckStoring & CategoryStoring,
        logStore: any LogStoring,
        days: any DayBoundaryProviding,
        timeSource: any TimeSource,
        changes: any ChangeNotifying,
        editor: CheckEditor,
        categoryEditor: CategoryEditor,
        layout: any TodayLayoutStoring,
        photos: PhotoStore? = nil,
        locale: Locale = .autoupdatingCurrent,
        toastDuration: Duration = .seconds(5)
    ) {
        self.checkStore = checkStore
        self.logStore = logStore
        self.days = days
        self.timeSource = timeSource
        self.changes = changes
        self.editor = editor
        self.categoryEditor = categoryEditor
        self.layoutStore = layout
        self.layout = layout.todayLayout
        self.photos = photos
        self.locale = locale
        self.toastDuration = toastDuration
    }

    /// Reads the categories, checks and today's logs again, then rebuilds everything shown.
    func reload() {
        let boundary = days.dayBoundary
        let today = boundary.calendarDay(containing: timeSource.now)
        // Set first, so a failed read can't send `rebuild` back here.
        logsDay = today
        do {
            categories = try checkStore.categories()
            checks = try checkStore.checks()
            let interval = boundary.interval(of: today)
            todaysLogs = try logStore.logs(from: interval.start, to: interval.end)
            errorMessage = nil
        } catch {
            errorMessage = String(localized: "Couldn’t read your checks.")
        }
        if let filterID, !categories.contains(where: { $0.id == filterID }) { self.filterID = nil }
        rebuild()
    }

    /// Recomputes the day without reading the store, unless the day has changed.
    func rebuild() {
        let now = timeSource.now
        let boundary = days.dayBoundary
        let today = boundary.calendarDay(containing: now)
        if let agendaToday, agendaToday != today {
            selectedDay = nil
            expandedOverrides = [:]
        }
        if logsDay != nil, logsDay != today {
            reload()
            return
        }
        agendaToday = today
        let agenda = DayAgenda(
            day: selectedDay, filter: filterID, categories: categories, checks: checks, logs: todaysLogs,
            now: now, boundary: boundary, locale: locale
        )
        let time = RelativeTime(boundary: boundary, locale: locale)
        let dayName = RepeatRule.shortDate(agenda.selectedDay, calendar: boundary.calendar, locale: locale)

        isEmpty = checks.isEmpty
        isToday = agenda.isToday
        dayTitle = agenda.dayTitle
        daySub = agenda.daySub
        strip = agenda.strip
        progress = agenda.progress
        nothingDueText = agenda.nothingDueText
        todayProgress = agenda.todayTotal == 0 ? 0 : Double(agenda.todayDoneCount) / Double(agenda.todayTotal)
        ringAccessibilityLabel = agenda.ringAccessibilityLabel
        sections = agenda.sections.map { section in
            let meta = if section.isAllDone, let last = section.lastLog {
                String(localized: "All done · last \(time.clockTime(last.date))")
            } else {
                section.repeatLabel
            }
            return TodaySection(
                category: section.category,
                meta: meta,
                progressText: section.isAllDone ? "✓ \(section.progressText)" : section.progressText,
                isAllDone: section.isAllDone,
                isExpanded: expandedOverrides[section.id] ?? !section.isAllDone,
                tiles: section.tasks.map { tile in
                    TodayTile(id: tile.id, content: Self.content(for: tile, isToday: agenda.isToday, dayName: dayName, time: time))
                }
            )
        }
    }

    // MARK: - Day and filter

    func select(_ day: CalendarDay) {
        selectedDay = day
        rebuild()
    }

    /// The Today tab: today, every category.
    func showToday() {
        selectedDay = nil
        filterID = nil
        rebuild()
    }

    /// Nil shows every category.
    func selectFilter(_ categoryID: UUID?) {
        filterID = categoryID
        rebuild()
    }

    /// Today, showing one category alone (a category reminder's tap).
    func focus(on categoryID: UUID) {
        selectedDay = nil
        // `reload` drops it if the category has gone.
        filterID = categoryID
        reload()
    }

    /// Opens or closes a section; the choice lasts until the day changes.
    func toggleSection(_ categoryID: UUID) {
        let isExpanded = sections.first { $0.id == categoryID }?.isExpanded ?? true
        expandedOverrides[categoryID] = !isExpanded
        rebuild()
    }

    /// Opens a section, as when tasks are added to it.
    func expandSection(_ categoryID: UUID) {
        expandedOverrides[categoryID] = true
        rebuild()
    }

    /// Grid ⇄ list, remembered in settings.
    func toggleLayout() {
        layout = layout == .grid ? .list : .grid
        layoutStore.todayLayout = layout
    }

    /// The category the Add sheet opens on: the filtered one, else Daily.
    var addTarget: UUID? { filterID }

    // MARK: - Logging

    func log(_ checkID: UUID, photoFileName: String? = nil) {
        guard isToday, let check = checks.first(where: { $0.id == checkID }) else { return }
        do {
            let outcome = try logStore.log(checkID, source: .app, at: timeSource.now, photoFileName: photoFileName)
            logCount += 1
            changes.didChange()
            reload()
            showToast(LogToast(
                message: photoFileName == nil
                    ? String(localized: "Logged · \(check.name)")
                    : String(localized: "Photo saved · \(check.name)"),
                outcome: outcome
            ))
        } catch {
            errorMessage = String(localized: "Couldn’t log \(check.name).")
        }
    }

    /// Saves a proof photo: it replaces today's photo on a retake, else it's a new log.
    func attachPhoto(_ image: UIImage, to checkID: UUID) {
        guard isToday, let photos, let check = checks.first(where: { $0.id == checkID }) else { return }
        do {
            let fileName = try photos.save(image)
            if let log = todaysLog(for: checkID), log.hasPhoto {
                try logStore.setPhoto(fileName, forLog: log.id)
                var updated = log
                updated.photoFileName = fileName
                logCount += 1
                changes.didChange()
                reload()
                showToast(LogToast(message: String(localized: "Photo saved · \(check.name)"), outcome: .refreshed(updated, previous: log)))
            } else {
                log(checkID, photoFileName: fileName)
            }
        } catch {
            errorMessage = String(localized: "Couldn’t save that photo.")
        }
    }

    private func todaysLog(for checkID: UUID) -> LogRecord? {
        todaysLogs.filter { $0.checkID == checkID }.max { $0.date < $1.date }
    }

    func undo() {
        guard let toast else { return }
        self.toast = nil
        do {
            try logStore.undo(toast.outcome)
            changes.didChange()
            reload()
        } catch {
            errorMessage = String(localized: "Couldn’t undo that.")
        }
    }

    func dismissToast() {
        toast = nil
    }

    // MARK: - Managing checks

    func check(_ id: UUID) -> CheckRecord? {
        checks.first { $0.id == id }
    }

    func removeRequest(for id: UUID) -> CheckManagementRequest? {
        guard let check = check(id) else { return nil }
        return .remove(check, logCount: (try? logStore.logCount(for: id)) ?? 0)
    }

    func canMove(_ id: UUID, by offset: Int) -> Bool {
        let order = siblings(of: id)
        guard let index = order.firstIndex(of: id) else { return false }
        return order.indices.contains(index + offset)
    }

    func rename(_ id: UUID, to name: String) {
        edit { try editor.rename(id, to: name) }
    }

    func setKind(_ kind: CheckKind, for id: UUID) {
        edit { try editor.setKind(kind, for: id) }
    }

    /// Moves a task within its category.
    func move(_ id: UUID, by offset: Int) {
        edit { try editor.move(id, by: offset, in: siblings(of: id)) }
    }

    /// A tile dropped on another in the same category takes its place.
    func move(_ id: UUID, to target: UUID) {
        guard check(id)?.categoryID == check(target)?.categoryID else { return }
        edit { try editor.move(id, to: target, in: siblings(of: id)) }
    }

    func remove(_ id: UUID) {
        if toast?.outcome.record.checkID == id { toast = nil }
        edit { try editor.remove(id) }
    }

    /// Every task, for the New category tip.
    var taskCount: Int { checks.count }

    /// The categories a task can move to: all but its own.
    func destinations(for id: UUID) -> [CategoryRecord] {
        guard let categoryID = check(id)?.categoryID else { return [] }
        return categories.filter { $0.id != categoryID }
    }

    func moveCheck(_ id: UUID, to categoryID: UUID) {
        edit { try categoryEditor.moveCheck(id, to: categoryID) }
    }

    // MARK: - Managing categories

    /// The confirmation for deleting a category; nil for Daily.
    func deletionRequest(for categoryID: UUID) -> CategoryDeletionRequest? {
        categoryEditor.deletionRequest(for: categoryID)
    }

    func deleteCategory(_ id: UUID, _ choice: CategoryDeletion) {
        if let checkID = toast?.outcome.record.checkID, check(checkID)?.categoryID == id { toast = nil }
        edit { try categoryEditor.delete(id, choice) }
    }

    /// The ids of the tasks in `id`'s category, in order.
    private func siblings(of id: UUID) -> [UUID] {
        guard let categoryID = check(id)?.categoryID else { return [] }
        return checks.filter { $0.categoryID == categoryID }.map(\.id)
    }

    private func edit(_ change: () throws -> Void) {
        do {
            try change()
            reload()
        } catch {
            errorMessage = String(localized: "Couldn’t change that check.")
        }
    }

    private func showToast(_ toast: LogToast) {
        self.toast = toast
        let id = toast.id
        let duration = toastDuration
        Task { [weak self] in
            try? await Task.sleep(for: duration)
            if self?.toast?.id == id { self?.toast = nil }
        }
    }

    private static func content(for tile: DayAgenda.Tile, isToday: Bool, dayName: String, time: RelativeTime) -> TaskTileContent {
        let name = tile.check.name
        let state: TaskTileContent.State
        let label: String
        if let log = tile.log {
            let clock = time.clockTime(log.date)
            state = .done(time: clock)
            label = String(localized: "\(name), logged \(clock) — tap to log again")
        } else if isToday {
            state = .toLog
            label = String(localized: "\(name), not logged — tap to log")
        } else {
            state = .upcoming
            label = String(localized: "\(name), upcoming on \(dayName)")
        }
        let hasPhoto = tile.log?.hasPhoto == true
        return TaskTileContent(
            name: name, kind: tile.check.kind, swatch: tile.swatch, state: state, hasPhoto: hasPhoto,
            accessibilityLabel: label,
            photoButtonLabel: hasPhoto ? String(localized: "Retake photo for \(name)") : String(localized: "Log \(name) with a photo")
        )
    }
}
