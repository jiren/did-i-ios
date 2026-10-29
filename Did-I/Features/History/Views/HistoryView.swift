import SwiftUI

/// Every log, by day, with a filter by check. Swipe a row to delete a wrong log.
struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    @Binding var tab: MainTab
    let onOpenCheck: (UUID) -> Void
    let onAddChecks: () -> Void

    @Environment(StoreChangeHub.self) private var changes

    init(
        viewModel: @autoclosure () -> HistoryViewModel,
        tab: Binding<MainTab>,
        onOpenCheck: @escaping (UUID) -> Void,
        onAddChecks: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel())
        _tab = tab
        self.onOpenCheck = onOpenCheck
        self.onAddChecks = onAddChecks
    }

    var body: some View {
        List {
            Section {
                filterBar
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.ground)
                    .listRowSeparator(.hidden)
            } header: {
                Text("History")
                    .font(.didHero)
                    .foregroundStyle(Color.ink)
                    .textCase(nil)
                    .padding(.top, 8)
                    .accessibilityAddTraits(.isHeader)
            }
            if viewModel.isEmpty {
                Text("No logs yet. Tap a check on Today to log it.")
                    .font(.didBody)
                    .foregroundStyle(Color.muted)
                    .listRowBackground(Color.ground)
                    .listRowSeparator(.hidden)
            }
            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(section.rows) { row in
                        Button { onOpenCheck(row.checkID) } label: { HistoryRowView(row: row) }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.ground)
                            .listRowSeparatorTint(Color.line)
                            .swipeActions {
                                Button(role: .destructive) { viewModel.delete(row.id) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text(section.title)
                        .font(.didSection)
                        .foregroundStyle(Color.ink)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.ground)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            FloatingTabBar(selection: $tab, onAdd: onAddChecks)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .task { viewModel.reload() }
        .onChange(of: changes.version) { viewModel.reload() }
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(viewModel.filters) { filter in
                    ChoiceChip(title: filter.title, isOn: viewModel.selectedCheckID == filter.id) {
                        viewModel.select(filter.id)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }
}

private struct HistoryRowView: View {
    let row: HistoryRow

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: row.kind.symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(row.swatch.foreground)
                .frame(width: 36, height: 36)
                .background(row.swatch.background, in: .circle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(row.checkName)
                    .font(.didRowTitle)
                    .foregroundStyle(Color.ink)
                Text(row.source)
                    .font(.didFootnoteRegular)
                    .foregroundStyle(Color.muted)
            }
            Spacer()
            if row.hasPhoto {
                Image(systemName: "camera.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.muted)
                    .accessibilityHidden(true)
            }
            Text(row.time)
                .font(.didEmphasis)
                .foregroundStyle(Color.ink)
        }
        .padding(.vertical, 6)
        .frame(minHeight: 48)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
