import Foundation
import Testing
import UIKit
@testable import Did_I

@MainActor
struct PhotoStoreTests {
    private let photos = PhotoStore(folder: URL.temporaryDirectory.appending(path: "PhotoStoreTests-\(UUID().uuidString)"))

    private func image(_ width: CGFloat, _ height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            UIColor.systemPurple.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    @Test func savesADownscaledPhotoAndAThumbnail() throws {
        let name = try photos.save(image(4000, 3000))
        let saved = try #require(photos.image(named: name))
        #expect(max(saved.size.width, saved.size.height) <= PhotoStore.maximumDimension)
        #expect(FileManager.default.fileExists(atPath: photos.thumbnailURL(for: name).path))
        #expect(photos.storedFileNames() == [name])
    }

    @Test func removesPhotosAndOrphans() throws {
        let kept = try photos.save(image(100, 100))
        let orphan = try photos.save(image(100, 100))
        photos.removeOrphans(keeping: [kept])
        #expect(photos.storedFileNames() == [kept])
        photos.removePhotos(named: [kept])
        #expect(photos.storedFileNames().isEmpty)
        #expect(photos.image(named: orphan) == nil)
    }

    @Test func retentionClearsOldPhotosButKeepsTheLogs() throws {
        let store = SwiftDataStore(container: try .app(inMemory: true))
        let check = try store.addChecks([CheckDraft(name: "Front door locked")])[0]
        let now = TestTime.date(2026, 10, 29, 9)
        let old = try photos.save(image(100, 100))
        let recent = try photos.save(image(100, 100))
        _ = try store.log(check.id, source: .app, at: TestTime.date(2026, 9, 1), photoFileName: old)
        _ = try store.log(check.id, source: .app, at: TestTime.date(2026, 10, 28), photoFileName: recent)

        PhotoRetention.sweep(logs: store, photos: photos, keep: .thirtyDays, now: now)
        #expect(photos.storedFileNames() == [recent])
        #expect(try store.logCount(for: check.id) == 2)
    }

    @Test(arguments: [(KeepPhotos.sevenDays, 7), (.thirtyDays, 30)])
    func cutoffs(keep: KeepPhotos, days: Int) {
        let calendar = TestTime.calendar()
        let now = TestTime.date(2026, 10, 29)
        #expect(keep.cutoff(before: now, calendar: calendar) == calendar.date(byAdding: .day, value: -days, to: now))
    }

    @Test func foreverKeepsEverything() {
        #expect(KeepPhotos.forever.cutoff(before: Date()) == nil)
    }
}

@MainActor
struct TodayPhotoTests {
    @Test func aRetakeReplacesTodaysPhotoAndUndoRestoresIt() throws {
        let clock = FixedTimeSource(TestTime.date(2026, 10, 29, 9))
        let store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
        let photos = PhotoStore(folder: URL.temporaryDirectory.appending(path: "TodayPhotoTests-\(UUID().uuidString)"))
        let changes = ChangeSpy()
        let check = try store.addChecks([CheckDraft(name: "Front door locked")])[0]
        let viewModel = TodayViewModel(
            checkStore: store, logStore: store, days: FixedDays(), timeSource: clock, changes: changes,
            editor: CheckEditor(store: store, changes: changes, photos: photos),
            categoryEditor: CategoryEditor(store: store, changes: changes, photos: photos), photos: photos,
            locale: Locale(identifier: "en_US"), toastDuration: .seconds(60)
        )
        viewModel.reload()
        let photo = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in }

        viewModel.attachPhoto(photo, to: check.id)
        let first = try #require(try store.latestLogs()[check.id]?.photoFileName)
        #expect(viewModel.toast?.message == "Photo saved · Front door locked")

        clock.now = clock.now.addingTimeInterval(3600)
        viewModel.reload()
        viewModel.attachPhoto(photo, to: check.id)
        #expect(try store.logCount(for: check.id) == 1)
        #expect(try store.latestLogs()[check.id]?.photoFileName != first)

        viewModel.undo()
        #expect(try store.latestLogs()[check.id]?.photoFileName == first)
    }
}
