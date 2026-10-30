import SwiftUI

/// "Delete “Bin night”?": delete its tasks too, or move them to Daily (`Plan.md`: ask each time).
struct CategoryDeletionModifier: ViewModifier {
    @Binding var request: CategoryDeletionRequest?
    let onDelete: (UUID, CategoryDeletion) -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            title,
            isPresented: Binding(get: { request != nil }, set: { if !$0 { request = nil } }),
            titleVisibility: .visible,
            presenting: request
        ) { request in
            if request.taskCount == 0 {
                Button(String(localized: "Delete category"), role: .destructive) {
                    onDelete(request.category.id, .deleteTasks)
                }
                .accessibilityIdentifier("category.delete.confirm")
            } else {
                Button(Self.deleteTasksTitle(request.taskCount), role: .destructive) {
                    onDelete(request.category.id, .deleteTasks)
                }
                .accessibilityIdentifier("category.delete.tasks")
                Button(Self.moveTasksTitle(request.taskCount)) {
                    onDelete(request.category.id, .moveTasksToDaily)
                }
                .accessibilityIdentifier("category.delete.move")
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: { request in
            Text(request.taskCount == 0
                ? String(localized: "It has no tasks.")
                : String(localized: "Deleted tasks take their logs and photos with them."))
        }
    }

    private var title: String {
        guard let request else { return "" }
        return String(localized: "Delete “\(request.category.name)”?")
    }

    static func deleteTasksTitle(_ count: Int) -> String {
        count == 1 ? String(localized: "Delete category and its task") : String(localized: "Delete category and its \(count) tasks")
    }

    static func moveTasksTitle(_ count: Int) -> String {
        count == 1 ? String(localized: "Move 1 task to Daily") : String(localized: "Move \(count) tasks to Daily")
    }
}

extension View {
    func categoryDeletion(_ request: Binding<CategoryDeletionRequest?>, onDelete: @escaping (UUID, CategoryDeletion) -> Void) -> some View {
        modifier(CategoryDeletionModifier(request: request, onDelete: onDelete))
    }
}
