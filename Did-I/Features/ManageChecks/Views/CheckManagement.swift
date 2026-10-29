import SwiftUI

/// What a screen asked to do to a check, driving the alerts and sheets in `checkManagement`.
enum CheckManagementRequest: Identifiable, Equatable {
    case rename(CheckRecord)
    case icon(CheckRecord)
    case remove(CheckRecord, logCount: Int)

    var id: String {
        switch self {
        case .rename(let check): "rename-\(check.id)"
        case .icon(let check): "icon-\(check.id)"
        case .remove(let check, _): "remove-\(check.id)"
        }
    }
}

/// The rename alert, icon sheet and remove confirmation, shared by Today and Detail.
struct CheckManagementModifier: ViewModifier {
    @Binding var request: CheckManagementRequest?
    let onRename: (UUID, String) -> Void
    let onPickKind: (UUID, CheckKind) -> Void
    let onRemove: (UUID) -> Void

    @State private var draftName = ""

    func body(content: Content) -> some View {
        content
            .alert(String(localized: "Rename check"), isPresented: isPresented(\.isRename)) {
                TextField(String(localized: "Name"), text: $draftName)
                    .accessibilityIdentifier("rename.field")
                Button(String(localized: "Save")) {
                    if case .rename(let check) = request { onRename(check.id, draftName) }
                }
                .accessibilityIdentifier("rename.save")
                Button(String(localized: "Cancel"), role: .cancel) {}
            }
            .sheet(isPresented: isPresented(\.isIcon)) {
                if case .icon(let check) = request {
                    IconPickerSheet(checkName: check.name, selected: check.kind) { onPickKind(check.id, $0) }
                }
            }
            .confirmationDialog(removeTitle, isPresented: isPresented(\.isRemove), titleVisibility: .visible) {
                Button(String(localized: "Remove check"), role: .destructive) {
                    if case .remove(let check, _) = request { onRemove(check.id) }
                }
                .accessibilityIdentifier("remove.confirm")
            } message: {
                Text(removeMessage)
            }
            .onChange(of: request) { _, newValue in
                if case .rename(let check) = newValue { draftName = check.name }
            }
    }

    private var removeTitle: String {
        guard case .remove(let check, _) = request else { return "" }
        return String(localized: "Remove “\(check.name)”?")
    }

    private var removeMessage: String {
        guard case .remove(_, let count) = request else { return "" }
        return count == 0
            ? String(localized: "It has no logs yet.")
            : String(localized: "Its \(count) logs and their photos are deleted too.")
    }

    private func isPresented(_ kind: KeyPath<CheckManagementRequest, Bool>) -> Binding<Bool> {
        Binding(
            get: { request?[keyPath: kind] ?? false },
            set: { if !$0 { request = nil } }
        )
    }
}

extension CheckManagementRequest {
    var isRename: Bool { if case .rename = self { true } else { false } }
    var isIcon: Bool { if case .icon = self { true } else { false } }
    var isRemove: Bool { if case .remove = self { true } else { false } }
}

extension View {
    func checkManagement(
        _ request: Binding<CheckManagementRequest?>,
        onRename: @escaping (UUID, String) -> Void,
        onPickKind: @escaping (UUID, CheckKind) -> Void,
        onRemove: @escaping (UUID) -> Void
    ) -> some View {
        modifier(CheckManagementModifier(request: request, onRename: onRename, onPickKind: onPickKind, onRemove: onRemove))
    }
}
