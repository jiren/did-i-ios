import SwiftUI
import TipKit

/// Today (`Main.dc.html`): the header, the grid of checks, Recent, and the floating bar.
struct TodayView: View {
    @State private var viewModel: TodayViewModel
    @State private var management: CheckManagementRequest?
    @State private var photoCheck: PhotoRequest?
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
                    TipView(EditTileTip())
                        .tipBackground(Color.surface)
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
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
        .fullScreenCover(item: $photoCheck) { request in
            PhotoCaptureView(checkName: request.checkName) { viewModel.attachPhoto($0, to: request.checkID) }
        }
        .checkManagement(
            $management,
            onRename: viewModel.rename,
            onPickKind: { viewModel.setKind($1, for: $0) },
            onRemove: viewModel.remove
        )
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
                    onPhoto: { photoCheck = PhotoRequest(checkID: tile.id, checkName: tile.content.name) }
                )
                .contextMenu { menu(for: tile.id) }
                .draggable(tile.id.uuidString) {
                    TileIcon(kind: tile.content.kind, swatch: tile.content.swatch, isDone: false)
                }
                .dropDestination(for: String.self) { items, _ in
                    guard let dragged = items.first.flatMap(UUID.init(uuidString:)) else { return false }
                    viewModel.move(dragged, to: tile.id)
                    return true
                }
            }
            AddTile(action: actions.addChecks)
                .accessibilityIdentifier("today.addTile")
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
    }

    @ViewBuilder
    private func menu(for id: UUID) -> some View {
        Button { actions.openCheck(id) } label: { Label("Details", systemImage: "clock.arrow.circlepath") }
        Button {
            EditTileTip().invalidate(reason: .actionPerformed)
            if let check = viewModel.check(id) { management = .rename(check) }
        } label: { Label("Rename", systemImage: "pencil") }
        Button {
            EditTileTip().invalidate(reason: .actionPerformed)
            if let check = viewModel.check(id) { management = .icon(check) }
        } label: { Label("Change icon", systemImage: "square.grid.2x2") }
        if viewModel.canMove(id, by: -1) {
            Button { viewModel.move(id, by: -1) } label: { Label("Move earlier", systemImage: "arrow.left") }
        }
        if viewModel.canMove(id, by: 1) {
            Button { viewModel.move(id, by: 1) } label: { Label("Move later", systemImage: "arrow.right") }
        }
        Divider()
        Button(role: .destructive) {
            management = viewModel.removeRequest(for: id)
        } label: { Label("Remove", systemImage: "trash") }
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
}

/// The check a proof photo is being taken for.
struct PhotoRequest: Identifiable {
    var id: UUID { checkID }
    let checkID: UUID
    let checkName: String
}
