import Foundation
import Testing
@testable import Did_I

@MainActor
struct AppSettingsTests {
    private func freshDefaults() -> UserDefaults {
        let name = "AppSettingsTests-\(UUID().uuidString)"
        return UserDefaults(suiteName: name)!
    }

    @Test func defaults() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.appearance == .system)
        #expect(settings.dayStartHour == 0)
        #expect(settings.keepPhotos == .thirtyDays)
        #expect(settings.todayLayout == .grid)
        #expect(settings.actionButtonCheckID == nil)
        #expect(settings.actionButtonStrongHaptic)
        #expect(!settings.actionButtonOpensCamera)
        #expect(!settings.hidesNamesOnLockScreen)
    }

    @Test func valuesPersist() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        let id = UUID()
        settings.appearance = .dark
        settings.dayStartHour = 4
        settings.keepPhotos = .forever
        settings.todayLayout = .list
        settings.actionButtonCheckID = id
        settings.actionButtonStrongHaptic = false
        settings.hidesNamesOnLockScreen = true

        let reread = AppSettings(defaults: defaults)
        #expect(reread.appearance == .dark)
        #expect(reread.dayBoundary.startHour == 4)
        #expect(reread.keepPhotos == .forever)
        #expect(reread.todayLayout == .list)
        #expect(reread.actionButtonCheckID == id)
        #expect(!reread.actionButtonStrongHaptic)
        #expect(reread.hidesNamesOnLockScreen)
    }

    @Test(arguments: [
        ("iPhone16,1", true), ("iPhone17,3", true), ("iPhone18,2", true),
        ("iPhone15,4", false), ("iPhone14,7", false), ("iPad16,3", false), ("arm64", false),
    ])
    func actionButtonModels(model: String, expected: Bool) {
        #expect(ActionButtonSupport.hasActionButton(modelIdentifier: model) == expected)
    }
}

@MainActor
struct SettingsViewModelTests {
    @Test func deletingLogsKeepsChecks() throws {
        let store = SwiftDataStore(container: try .app(inMemory: true))
        let photos = PhotoRemovalSpy()
        let changes = ChangeSpy()
        let check = try store.addChecks([CheckDraft(name: "Front door locked")])[0]
        _ = try store.log(check.id, source: .app, at: Date(), photoFileName: "a.heic")
        let viewModel = SettingsViewModel(store: store, changes: changes, photos: photos)
        viewModel.load()

        viewModel.deleteAllLogs()
        #expect(try store.logCount(for: check.id) == 0)
        #expect(viewModel.checks.count == 1)
        #expect(photos.removed == ["a.heic"])

        viewModel.deleteEverything()
        #expect(viewModel.checks.isEmpty)
        #expect(changes.count == 2)
    }
}
