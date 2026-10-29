import Foundation
import Testing
@testable import Did_I

final class PhotoRemovalSpy: PhotoFileRemoving {
    private(set) var removed: [String] = []
    func removePhotos(named fileNames: [String]) { removed += fileNames }
}

@MainActor
struct CheckEditorTests {
    @Test func removingDeletesPhotos() throws {
        let store = SwiftDataStore(container: try .app(inMemory: true))
        let photos = PhotoRemovalSpy()
        let changes = ChangeSpy()
        let editor = CheckEditor(store: store, changes: changes, photos: photos)
        let check = try store.addChecks([CheckDraft(name: "Front door locked")])[0]
        _ = try store.log(check.id, source: .app, at: Date(), photoFileName: "door.heic")
        try editor.remove(check.id)
        #expect(photos.removed == ["door.heic"])
        #expect(changes.count == 1)
    }

    @Test func movesAreClamped() throws {
        let store = SwiftDataStore(container: try .app(inMemory: true))
        let editor = CheckEditor(store: store, changes: ChangeSpy(), photos: nil)
        let ids = try store.addChecks(["A", "B", "C"].map { CheckDraft(name: $0) }).map(\.id)
        try editor.move(ids[0], by: 10, in: ids)
        #expect(try store.checks().map(\.name) == ["B", "C", "A"])
    }
}
