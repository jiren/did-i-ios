import Foundation

/// Rename, re-icon, reorder and remove checks; shared by Today's tile menu and Detail.
final class CheckEditor {
    private let store: any CheckStoring
    private let changes: any ChangeNotifying
    private let photos: (any PhotoFileRemoving)?

    init(store: any CheckStoring, changes: any ChangeNotifying, photos: (any PhotoFileRemoving)?) {
        self.store = store
        self.changes = changes
        self.photos = photos
    }

    func rename(_ id: UUID, to name: String) throws {
        try store.rename(id, to: name)
        changes.didChange()
    }

    func setKind(_ kind: CheckKind, for id: UUID) throws {
        try store.setKind(kind, for: id)
        changes.didChange()
    }

    /// Moves a check `offset` places within `order` (Today's ids, in order).
    func move(_ id: UUID, by offset: Int, in order: [UUID]) throws {
        guard let index = order.firstIndex(of: id) else { return }
        let target = min(max(index + offset, 0), order.count - 1)
        guard target != index else { return }
        var ids = order
        ids.remove(at: index)
        ids.insert(id, at: target)
        try store.reorder(ids)
        changes.didChange()
    }

    /// Moves a dragged check to where `target` is.
    func move(_ id: UUID, to target: UUID, in order: [UUID]) throws {
        guard id != target, let from = order.firstIndex(of: id), let to = order.firstIndex(of: target) else { return }
        try move(id, by: to - from, in: order)
    }

    func remove(_ id: UUID) throws {
        let photoNames = try store.removeCheck(id)
        photos?.removePhotos(named: photoNames)
        changes.didChange()
    }
}
