import Foundation
import Observation

/// Settings' actions that touch data; plain preferences bind straight to `AppSettings`.
@Observable
final class SettingsViewModel {
    private(set) var checks: [CheckRecord] = []
    private(set) var message: String?

    @ObservationIgnored private let store: any CheckStoring & LogStoring
    @ObservationIgnored private let changes: any ChangeNotifying
    @ObservationIgnored private let photos: (any PhotoFileRemoving)?

    init(store: any CheckStoring & LogStoring, changes: any ChangeNotifying, photos: (any PhotoFileRemoving)?) {
        self.store = store
        self.changes = changes
        self.photos = photos
    }

    func load() {
        checks = (try? store.checks()) ?? []
    }

    func deleteAllLogs() {
        perform(String(localized: "Every log and photo is deleted.")) { try store.deleteAllLogs() }
    }

    func deleteEverything() {
        perform(String(localized: "Everything is deleted.")) { try store.deleteEverything() }
    }

    private func perform(_ done: String, _ delete: () throws -> [String]) {
        do {
            photos?.removePhotos(named: try delete())
            changes.didChange()
            load()
            message = done
        } catch {
            message = String(localized: "Couldn’t delete your data.")
        }
    }

    static var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return String(localized: "Version \(version) (\(build))")
    }
}
