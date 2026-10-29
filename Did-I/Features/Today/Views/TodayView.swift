import SwiftUI

/// Today (`Main.dc.html`): the header, the grid of checks, Recent, and the floating bar.
struct TodayView: View {
    @State private var viewModel: TodayViewModel
    @Binding var tab: MainTab
    let actions: TodayActions

    @Environment(StoreChangeHub.self) private var changes
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(viewModel: @autoclosure () -> TodayViewModel, tab: Binding<MainTab>, actions: TodayActions) {
        _viewModel = State(initialValue: viewModel())
        _tab = tab
        self.actions = actions
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TodayHeader(
                    dateText: viewModel.dateText,
                    summary: viewModel.summary,
                    showsSummary: !viewModel.isEmpty,
                    onSettings: actions.openSettings
                )
                if viewModel.isEmpty {
                    TodayEmptyState(onAdd: actions.addChecks)
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                } else {
                    grid
                }
                if !viewModel.recent.isEmpty {
                    RecentList(rows: viewModel.recent, onOpen: actions.openCheck, onSeeAll: actions.seeAll)
                        .padding(.horizontal, 24)
                        .padding(.top, 22)
                }
                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.didFootnote)
                        .foregroundStyle(Color.muted)
                        .padding(24)
                }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .background(Color.ground)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .sensoryFeedback(.success, trigger: viewModel.logCount)
        .task {
            viewModel.reload()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                viewModel.rebuild()
            }
        }
        .onChange(of: changes.version) { viewModel.reload() }
    }

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: count)
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.tiles) { tile in
                CheckTile(
                    content: tile.content,
                    onLog: { viewModel.log(tile.id) },
                    onPhoto: { actions.takePhoto(tile.id) }
                )
                .contextMenu { actions.tileMenu(tile.id) }
            }
            AddTile(action: actions.addChecks)
                .accessibilityIdentifier("today.addTile")
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if let toast = viewModel.toast {
                UndoToast(message: toast.message, onUndo: viewModel.undo)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityIdentifier("today.toast")
            }
            FloatingTabBar(selection: $tab, onAdd: actions.addChecks)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .animation(.snappy, value: viewModel.toast)
    }
}

/// What Today hands back to the root: navigation and sheets it doesn't own.
struct TodayActions {
    var addChecks: () -> Void = {}
    var openSettings: () -> Void = {}
    var openCheck: (UUID) -> Void = { _ in }
    var seeAll: () -> Void = {}
    var takePhoto: (UUID) -> Void = { _ in }
    var tileMenu: (UUID) -> TileMenu = { _ in TileMenu() }
}

/// A tile's context menu, supplied by the root so Today doesn't know about editing.
struct TileMenu: View {
    var items: [TileMenuItem] = []

    var body: some View {
        ForEach(items) { item in
            Button(role: item.isDestructive ? .destructive : nil, action: item.action) {
                Label(item.title, systemImage: item.systemImage)
            }
        }
    }
}

struct TileMenuItem: Identifiable {
    let id = UUID()
    var title: String
    var systemImage: String
    var isDestructive = false
    var action: () -> Void
}
