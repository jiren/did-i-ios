import Foundation

/// Delete and reorder categories and move tasks between them; shared by Today, Detail and Categories.
final class CategoryEditor {
    private let store: any CheckStoring & CategoryStoring
    private let changes: any ChangeNotifying
    private let photos: (any PhotoFileRemoving)?

    init(store: any CheckStoring & CategoryStoring, changes: any ChangeNotifying, photos: (any PhotoFileRemoving)?) {
        self.store = store
        self.changes = changes
        self.photos = photos
    }

    /// What deleting `id` would ask: its name and how many tasks it has. Nil for Daily.
    func deletionRequest(for id: UUID) -> CategoryDeletionRequest? {
        guard let category = try? store.category(id: id), !category.isDefault else { return nil }
        let count = ((try? store.checks()) ?? []).filter { $0.categoryID == id }.count
        return CategoryDeletionRequest(category: category, taskCount: count)
    }

    func delete(_ id: UUID, _ deletion: CategoryDeletion) throws {
        let photoNames = try store.deleteCategory(id, deletion)
        photos?.removePhotos(named: photoNames)
        changes.didChange()
    }

    func moveCheck(_ id: UUID, to categoryID: UUID) throws {
        try store.moveCheck(id, to: categoryID)
        changes.didChange()
    }

    func reorder(_ ids: [UUID]) throws {
        try store.reorderCategories(ids)
        changes.didChange()
    }
}

/// A category about to be deleted, for the confirmation that asks what happens to its tasks.
struct CategoryDeletionRequest: Identifiable, Equatable {
    var category: CategoryRecord
    var taskCount: Int

    var id: UUID { category.id }
}
