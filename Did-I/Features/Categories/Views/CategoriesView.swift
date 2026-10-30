import SwiftUI

/// Settings › Categories: tap to edit, drag to reorder, swipe to delete (never Daily).
struct CategoriesSettingsView: View {
    @State private var viewModel: CategoriesSettingsViewModel
    let onNew: () -> Void
    let onEdit: (UUID) -> Void

    @Environment(StoreChangeHub.self) private var changes

    init(viewModel: @autoclosure () -> CategoriesSettingsViewModel, onNew: @escaping () -> Void, onEdit: @escaping (UUID) -> Void) {
        _viewModel = State(initialValue: viewModel())
        self.onNew = onNew
        self.onEdit = onEdit
    }

    var body: some View {
        List {
            Section {
                ScreenHeader(backTitle: String(localized: "Settings"), title: String(localized: "Categories"))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section {
                ForEach(viewModel.current) { row in rowView(row) }
                    .onMove(perform: viewModel.move)
                Button(action: onNew) {
                    Label("New category", systemImage: "plus")
                        .font(.didRowTitle)
                        .foregroundStyle(Color.linkText)
                        .frame(minHeight: 44)
                }
                .listRowBackground(Color.surface)
                .accessibilityIdentifier("categories.new")
            } footer: {
                Text("Hold and drag to reorder. Daily is always there.")
                    .font(.didFootnoteRegular)
                    .foregroundStyle(Color.muted)
            }
            if !viewModel.past.isEmpty {
                Section {
                    ForEach(viewModel.past) { row in rowView(row) }
                } header: {
                    SectionLabel(title: String(localized: "Past"))
                }
            }
            if let message = viewModel.errorMessage {
                Text(message).font(.didFootnote).foregroundStyle(Color.muted).listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.ground)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .task { viewModel.load() }
        .onChange(of: changes.version) { viewModel.load() }
        .categoryDeletion($viewModel.deletion, onDelete: viewModel.delete)
    }

    private func rowView(_ row: CategoriesSettingsViewModel.Row) -> some View {
        Button { onEdit(row.id) } label: {
            HStack(spacing: 12) {
                CategoryBadge(icon: row.category.icon, colour: row.category.colour, size: 36, cornerRadius: 12)
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.category.name).font(.didRowTitle).foregroundStyle(Color.ink)
                    Text(row.detail).font(.didFootnoteRegular).foregroundStyle(Color.muted)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.muted)
            }
            .frame(minHeight: 52)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.surface)
        .swipeActions {
            if !row.category.isDefault {
                Button(String(localized: "Delete"), role: .destructive) { viewModel.askToDelete(row.id) }
            }
        }
        .accessibilityIdentifier("categories.row.\(row.category.name)")
    }
}
