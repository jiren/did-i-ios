import Foundation
import Observation
import UIKit

/// The confirmation after an Action Button press (`Logged.dc.html`).
@Observable
final class LoggedViewModel {
    private(set) var sourceText = ""
    private(set) var title = ""
    private(set) var whenText = ""
    private(set) var hasPhoto = false
    private(set) var isUndone = false
    private(set) var checkName = ""

    @ObservationIgnored let request: LoggedRequest
    @ObservationIgnored private let store: any CheckStoring & LogStoring
    @ObservationIgnored private let days: any DayBoundaryProviding
    @ObservationIgnored private let changes: any ChangeNotifying
    @ObservationIgnored private let photos: PhotoStore?
    @ObservationIgnored private let locale: Locale

    init(
        request: LoggedRequest,
        store: any CheckStoring & LogStoring,
        days: any DayBoundaryProviding,
        changes: any ChangeNotifying,
        photos: PhotoStore?,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.request = request
        self.store = store
        self.days = days
        self.changes = changes
        self.photos = photos
        self.locale = locale
    }

    func load() {
        guard let log = try? store.logs(for: nil, limit: 200).first(where: { $0.id == request.logID }),
              let check = try? store.check(id: log.checkID) else {
            isUndone = true
            return
        }
        let time = RelativeTime(boundary: days.dayBoundary, locale: locale)
        checkName = check.name
        sourceText = log.source == .actionButton
            ? String(localized: "Logged with Action Button")
            : String(localized: "Logged · \(log.source.label)")
        title = String(localized: "\(check.name).")
        whenText = String(localized: "\(time.weekday(log.date)) · \(time.clockTimeWithSeconds(log.date))")
        hasPhoto = log.hasPhoto
    }

    func undo() {
        if let photo = try? store.deleteLog(request.logID) { photos?.removePhotos(named: [photo]) }
        changes.didChange()
        isUndone = true
    }

    func attachPhoto(_ image: UIImage) {
        guard let photos, let fileName = try? photos.save(image) else { return }
        try? store.setPhoto(fileName, forLog: request.logID)
        changes.didChange()
        load()
    }
}
