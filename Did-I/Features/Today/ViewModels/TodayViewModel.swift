import Foundation
import Observation

/// Provides the day's boundary; `AppSettings` in the app, a fixed one in tests.
protocol DayBoundaryProviding: AnyObject {
    var dayBoundary: DayBoundary { get }
}

extension AppSettings: DayBoundaryProviding {}

@Observable
final class TodayViewModel {
    private(set) var dateText = ""
    private(set) var tiles: [TodayTile] = []
    private(set) var summary = TodaySummary(checks: [], doneIDs: [])
    private(set) var recent: [RecentRow] = []
    private(set) var toast: LogToast?
    private(set) var errorMessage: String?
    /// Bumped on each log, to play the success haptic.
    private(set) var logCount = 0

    var isEmpty: Bool { tiles.isEmpty }

    @ObservationIgnored private let checkStore: any CheckStoring
    @ObservationIgnored private let logStore: any LogStoring
    @ObservationIgnored private let days: any DayBoundaryProviding
    @ObservationIgnored private let timeSource: any TimeSource
    @ObservationIgnored private let changes: any ChangeNotifying
    @ObservationIgnored private let editor: CheckEditor
    @ObservationIgnored private let locale: Locale
    @ObservationIgnored private let toastDuration: Duration

    @ObservationIgnored private var checks: [CheckRecord] = []
    @ObservationIgnored private var latest: [UUID: LogRecord] = [:]
    @ObservationIgnored private var recentLogs: [LogRecord] = []

    init(
        checkStore: any CheckStoring,
        logStore: any LogStoring,
        days: any DayBoundaryProviding,
        timeSource: any TimeSource,
        changes: any ChangeNotifying,
        editor: CheckEditor,
        locale: Locale = .autoupdatingCurrent,
        toastDuration: Duration = .seconds(5)
    ) {
        self.checkStore = checkStore
        self.logStore = logStore
        self.days = days
        self.timeSource = timeSource
        self.changes = changes
        self.editor = editor
        self.locale = locale
        self.toastDuration = toastDuration
    }

    /// Reads the checks and logs again, then rebuilds everything shown.
    func reload() {
        do {
            checks = try checkStore.checks()
            latest = try logStore.latestLogs()
            recentLogs = try logStore.logs(for: nil, limit: 3)
            errorMessage = nil
        } catch {
            errorMessage = String(localized: "Couldn’t read your checks.")
        }
        rebuild()
    }

    /// Recomputes times ("2h ago") without reading the store.
    func rebuild() {
        let now = timeSource.now
        let boundary = days.dayBoundary
        let time = RelativeTime(boundary: boundary, locale: locale)
        let doneToday = Set(latest.values.filter { boundary.isInSameDay($0.date, as: now) }.map(\.checkID))

        dateText = now.formatted(
            Date.FormatStyle(locale: locale, calendar: boundary.calendar, timeZone: boundary.calendar.timeZone)
                .weekday(.wide).month(.abbreviated).day()
        )
        summary = TodaySummary(checks: checks, doneIDs: doneToday)

        var swatches: [UUID: TileSwatch] = [:]
        tiles = checks.enumerated().map { position, check in
            let swatch = TileSwatch.at(position: position)
            swatches[check.id] = swatch
            let log = latest[check.id].flatMap { doneToday.contains(check.id) ? $0 : nil }
            return TodayTile(id: check.id, content: Self.content(for: check, log: log, swatch: swatch, time: time, now: now))
        }

        recent = recentLogs.compactMap { log in
            guard let check = checks.first(where: { $0.id == log.checkID }) else { return nil }
            let when = boundary.isInSameDay(log.date, as: now) ? time.clockTime(log.date) : time.dayAndTime(log.date, now: now)
            return RecentRow(
                id: log.id,
                checkID: check.id,
                title: check.name,
                meta: log.hasPhoto ? String(localized: "\(when) · photo") : when,
                swatch: swatches[check.id] ?? .violet
            )
        }
    }

    func log(_ checkID: UUID, photoFileName: String? = nil) {
        guard let check = checks.first(where: { $0.id == checkID }) else { return }
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
        guard let index = checks.firstIndex(where: { $0.id == id }) else { return false }
        return checks.indices.contains(index + offset)
    }

    func rename(_ id: UUID, to name: String) {
        edit { try editor.rename(id, to: name) }
    }

    func setKind(_ kind: CheckKind, for id: UUID) {
        edit { try editor.setKind(kind, for: id) }
    }

    func move(_ id: UUID, by offset: Int) {
        edit { try editor.move(id, by: offset, in: checks.map(\.id)) }
    }

    /// A tile dropped on another takes its place.
    func move(_ id: UUID, to target: UUID) {
        edit { try editor.move(id, to: target, in: checks.map(\.id)) }
    }

    func remove(_ id: UUID) {
        if toast?.outcome.record.checkID == id { toast = nil }
        edit { try editor.remove(id) }
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

    private static func content(
        for check: CheckRecord, log: LogRecord?, swatch: TileSwatch, time: RelativeTime, now: Date
    ) -> CheckTileContent {
        guard let log else {
            return CheckTileContent(
                name: check.name, kind: check.kind, swatch: swatch, isDone: false, hasPhoto: false,
                timeText: String(localized: "Tap to log"),
                detailText: String(localized: "Not yet today"),
                accessibilityLabel: String(localized: "\(check.name), not logged today. Tap to log."),
                photoButtonLabel: String(localized: "Log \(check.name) with a photo")
            )
        }
        let clock = time.clockTime(log.date)
        let ago = time.ago(log.date, now: now)
        return CheckTileContent(
            name: check.name, kind: check.kind, swatch: swatch, isDone: true, hasPhoto: log.hasPhoto,
            timeText: clock,
            detailText: log.hasPhoto ? String(localized: "\(ago) · photo") : ago,
            accessibilityLabel: String(localized: "\(check.name), logged \(clock). Tap to log again."),
            photoButtonLabel: log.hasPhoto
                ? String(localized: "Retake photo for \(check.name)")
                : String(localized: "Log \(check.name) with a photo")
        )
    }
}
