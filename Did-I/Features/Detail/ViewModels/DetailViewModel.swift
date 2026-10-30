import Foundation
import Observation
import UIKit

/// One log on Detail's timeline.
struct TimelineItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var subtitle: String
    var photoFileName: String?
}

/// Check detail (`Detail.dc.html`): the latest log, its photo, the nudge switch and the history.
@Observable
final class DetailViewModel {
    static let timelineLimit = 50

    private(set) var check: CheckRecord?
    /// The check's category, shown in the Category row.
    private(set) var category: CategoryRecord?
    /// Every category, for moving the check to another.
    private(set) var categories: [CategoryRecord] = []
    private(set) var swatch: TileSwatch = .violet
    /// "Locked at 8:42 AM", or "Not logged yet".
    private(set) var headline = ""
    /// "Today · 2h 9m ago".
    private(set) var subheadline = ""
    private(set) var latestPhoto: UIImage?
    private(set) var latestPhotoCaption = ""
    private(set) var latestPhotoFileName: String?
    private(set) var timeline: [TimelineItem] = []
    private(set) var countText = ""
    private(set) var hasMoreThanShown = false
    private(set) var toast: LogToast?
    private(set) var logCount = 0
    private(set) var isRemoved = false
    private(set) var errorMessage: String?

    @ObservationIgnored let checkID: UUID
    @ObservationIgnored private let checkStore: any CheckStoring & CategoryStoring
    @ObservationIgnored private let logStore: any LogStoring
    @ObservationIgnored private let days: any DayBoundaryProviding
    @ObservationIgnored private let timeSource: any TimeSource
    @ObservationIgnored private let changes: any ChangeNotifying
    @ObservationIgnored private let editor: CheckEditor
    @ObservationIgnored private let photos: PhotoStore?
    @ObservationIgnored private let locale: Locale
    @ObservationIgnored private var logs: [LogRecord] = []
    @ObservationIgnored private var total = 0

    init(
        checkID: UUID,
        checkStore: any CheckStoring & CategoryStoring,
        logStore: any LogStoring,
        days: any DayBoundaryProviding,
        timeSource: any TimeSource,
        changes: any ChangeNotifying,
        editor: CheckEditor,
        photos: PhotoStore?,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.checkID = checkID
        self.checkStore = checkStore
        self.logStore = logStore
        self.days = days
        self.timeSource = timeSource
        self.changes = changes
        self.editor = editor
        self.photos = photos
        self.locale = locale
    }

    func reload() {
        do {
            guard let check = try checkStore.check(id: checkID) else {
                isRemoved = true
                return
            }
            self.check = check
            categories = try checkStore.categories()
            category = categories.first { $0.id == check.categoryID }
            let position = try checkStore.checks().firstIndex { $0.id == checkID } ?? 0
            swatch = TileSwatch.at(position: position)
            logs = try logStore.logs(for: checkID, limit: Self.timelineLimit)
            total = try logStore.logCount(for: checkID)
        } catch {
            errorMessage = String(localized: "Couldn’t read this check.")
        }
        rebuild()
    }

    func rebuild() {
        guard let check else { return }
        let now = timeSource.now
        let time = RelativeTime(boundary: days.dayBoundary, locale: locale)
        if let latest = logs.first {
            headline = String(localized: "\(CheckName.state(of: check.name)) at \(time.clockTime(latest.date))")
            subheadline = String(localized: "\(time.dayName(latest.date, now: now)) · \(time.ago(latest.date, now: now))")
        } else {
            headline = String(localized: "Not logged yet")
            subheadline = String(localized: "Log it below, or from Today.")
        }
        let photoLog = logs.first { $0.hasPhoto }
        if photoLog?.photoFileName != latestPhotoFileName {
            latestPhotoFileName = photoLog?.photoFileName
            latestPhoto = photoLog?.photoFileName.flatMap { photos?.thumbnail(named: $0) }
        }
        latestPhotoCaption = photoLog.map { time.dayAndTime($0.date, now: now) } ?? ""
        timeline = logs.map {
            TimelineItem(
                id: $0.id,
                title: time.dayAndTime($0.date, now: now),
                subtitle: $0.source.label(hasPhoto: $0.hasPhoto),
                photoFileName: $0.photoFileName
            )
        }
        countText = total == 1 ? String(localized: "1 log") : String(localized: "\(total) logs")
        hasMoreThanShown = total > logs.count
    }

    func fullPhoto() -> UIImage? {
        latestPhotoFileName.flatMap { photos?.image(named: $0) }
    }

    func setNudgesOnLeavingHome(_ isOn: Bool) {
        do {
            try checkStore.setNudgesOnLeavingHome(isOn, for: checkID)
            check?.nudgesOnLeavingHome = isOn
            changes.didChange()
        } catch {
            errorMessage = String(localized: "Couldn’t change that.")
        }
    }

    /// Moves the check to the end of another category.
    func moveToCategory(_ categoryID: UUID) {
        guard categoryID != category?.id else { return }
        do {
            try checkStore.moveCheck(checkID, to: categoryID)
            changes.didChange()
            reload()
        } catch {
            errorMessage = String(localized: "Couldn’t move this check.")
        }
    }

    func logAgain() {
        guard let check else { return }
        do {
            let outcome = try logStore.log(checkID, source: .app, at: timeSource.now, photoFileName: nil)
            logCount += 1
            changes.didChange()
            reload()
            showToast(LogToast(message: String(localized: "Logged · \(check.name)"), outcome: outcome))
        } catch {
            errorMessage = String(localized: "Couldn’t log \(check.name).")
        }
    }

    /// Logged today, so it can be marked as not done.
    var isDoneToday: Bool {
        logs.first.map { days.dayBoundary.isInSameDay($0.date, as: timeSource.now) } ?? false
    }

    /// "Mark as not done": removes today's logs, with Undo on the toast.
    func markNotDone() {
        guard let check else { return }
        let today = days.dayBoundary.day(containing: timeSource.now)
        do {
            guard let outcome = try logStore.unlog(checkID, from: today.start, to: today.end) else { return }
            changes.didChange()
            reload()
            showToast(LogToast(message: String(localized: "Not done · \(check.name)"), outcome: outcome))
        } catch {
            errorMessage = String(localized: "Couldn’t change \(check.name).")
        }
    }

    func undo() {
        guard let toast else { return }
        self.toast = nil
        try? logStore.undo(toast.outcome)
        changes.didChange()
        reload()
    }

    func deleteLog(_ id: UUID) {
        do {
            if let photo = try logStore.deleteLog(id) { photos?.removePhotos(named: [photo]) }
            if toast?.outcome.record.id == id { toast = nil }
            changes.didChange()
            reload()
        } catch {
            errorMessage = String(localized: "Couldn’t delete that log.")
        }
    }

    var removeRequest: CheckManagementRequest? {
        check.map { .remove($0, logCount: total) }
    }

    func rename(to name: String) {
        try? editor.rename(checkID, to: name)
        reload()
    }

    func setKind(_ kind: CheckKind) {
        try? editor.setKind(kind, for: checkID)
        reload()
    }

    func remove() {
        do {
            try editor.remove(checkID)
            isRemoved = true
        } catch {
            errorMessage = String(localized: "Couldn’t remove this check.")
        }
    }

    private func showToast(_ toast: LogToast) {
        self.toast = toast
        let id = toast.id
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            if self?.toast?.id == id { self?.toast = nil }
        }
    }
}
