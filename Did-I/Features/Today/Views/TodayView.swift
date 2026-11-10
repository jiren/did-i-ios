import SwiftUI
import TipKit

/// Today (`Main.dc.html`, compact): the day and buttons, the 7-day strip, the pinned progress bar and filters, one
/// collapsible section per due category (tiles or rows), and the floating bar.
struct TodayView: View {
    @State private var viewModel: TodayViewModel
    @State private var management: CheckManagementRequest?
    @State private var photoCheck: PhotoRequest?
    @State private var deletion: CategoryDeletionRequest?
    /// The scroll offset at which the progress bar pins, and whether it has.
    @State private var headerHeight: CGFloat = 300
    @State private var isBarStuck = false
    @Binding var tab: MainTab
    /// A category to show alone on today, from a category reminder.
    let focus: CategoryFocus?
    let actions: TodayActions

    @Environment(StoreChangeHub.self) private var changes
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(viewModel: @autoclosure () -> TodayViewModel, tab: Binding<MainTab>, focus: CategoryFocus? = nil, actions: TodayActions) {
        _viewModel = State(initialValue: viewModel())
        _tab = tab
        self.focus = focus
        self.actions = actions
    }

    var body: some View {
        ScrollViewReader { scroller in
            scrollView
                .safeAreaInset(edge: .bottom) {
                    bottomBar {
                        viewModel.showToday()
                        withAnimation(reduceMotion ? nil : .snappy) { scroller.scrollTo(Self.topID, anchor: .top) }
                    }
                }
        }
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
        .onChange(of: focus, initial: true) { _, focus in
            if let focus { viewModel.focus(on: focus.categoryID) }
        }
        .onChange(of: viewModel.taskCount, initial: true) { _, count in NewCategoryTip.taskCount = count }
        .categoryDeletion($deletion, onDelete: viewModel.deleteCategory)
        .onChange(of: viewModel.toast) { _, toast in
            if let toast { AccessibilityNotification.Announcement(toast.message).post() }
        }
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

    /// The scroll position Today goes back to.
    private static let topID = "today.top"

    private var header: some View {
        TodayHeader(
            dayTitle: viewModel.dayTitle, daySub: viewModel.daySub, layout: viewModel.layout,
            onToggleLayout: viewModel.toggleLayout, onCategories: actions.openCategories, onSettings: actions.openSettings
        )
        .id(Self.topID)
    }

    private var scrollView: some View {
        ScrollView {
            if viewModel.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    TodayEmptyState(onAdd: { actions.addChecks(nil) })
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                }
            } else {
                calendar
            }
        }
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > headerHeight
        } action: { _, isStuck in
            isBarStuck = isStuck
        }
    }

    private var calendar: some View {
        // Pinned, the block would cover much of the screen at accessibility sizes.
        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: dynamicTypeSize.isAccessibilitySize ? [] : [.sectionHeaders]) {
            VStack(alignment: .leading, spacing: 0) {
                header
                DayStrip(days: viewModel.strip, onSelect: viewModel.select)
                    .padding(.top, 12)
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
            Section {
                content
            } header: {
                stickyBlock
            }
        }
        .padding(.bottom, 24)
    }

    /// The progress bar and the filters, pinned together under the top as the page scrolls.
    private var stickyBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressBarCard(progress: viewModel.progress, isToday: viewModel.isToday, isStuck: isBarStuck)
                .padding(.horizontal, 20)
                .accessibilityIdentifier("today.progress")
            CategoryFilter(
                categories: viewModel.categories,
                selection: viewModel.filterID,
                onSelect: viewModel.selectFilter,
                onNew: actions.newCategory,
                onEdit: actions.editCategory,
                onDelete: { deletion = viewModel.deletionRequest(for: $0) }
            )
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.ground)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            TipView(EditTileTip())
                .tipBackground(Color.surface)
                .autoDismissing(EditTileTip())
            ForEach(viewModel.sections) { section in
                if let part = section.partHeader {
                    SectionLabel(title: part.title)
                        .padding(.top, section.id == viewModel.sections.first?.id ? 0 : 6)
                        .accessibilityIdentifier("today.part.\(part.rawValue)")
                }
                TodaySectionView(
                    section: section,
                    layout: viewModel.layout,
                    onToggle: { viewModel.toggleSection(section.id) },
                    onLog: { viewModel.log($0) },
                    onPhoto: { photoCheck = $0 },
                    onAdd: {
                        viewModel.expandSection(section.id)
                        actions.addChecks(section.category.id)
                    },
                    menu: { menu(for: $0) },
                    onDrop: { viewModel.move($0, to: $1) },
                    onEdit: actions.editCategory,
                    onDelete: { deletion = viewModel.deletionRequest(for: $0) }
                )
            }
            if let text = viewModel.nothingDueText {
                NothingDueCard(text: text)
            }
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.didFootnote)
                    .foregroundStyle(Color.muted)
            }
            if viewModel.showsTemplateSuggestions {
                TemplateSuggestionsRow(
                    items: viewModel.templateSuggestions,
                    onPick: actions.newCategoryFromTemplate,
                    onSeeAll: actions.newCategory
                )
                // Edge to edge, so the cards scroll under the screen's sides.
                .padding(.horizontal, -20)
                .padding(.top, 10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func menu(for id: UUID) -> some View {
        Button { actions.openCheck(id) } label: { Label("Details", systemImage: "clock.arrow.circlepath") }
        if viewModel.isDoneToday(id) {
            Button { viewModel.markNotDone(id) } label: { Label("Mark as not done", systemImage: "arrow.uturn.backward") }
        }
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
        let destinations = viewModel.destinations(for: id)
        if !destinations.isEmpty {
            Menu {
                ForEach(destinations) { category in
                    Button(category.name) { viewModel.moveCheck(id, to: category.id) }
                }
            } label: { Label("Move to", systemImage: "folder") }
        }
        Divider()
        Button(role: .destructive) {
            management = viewModel.removeRequest(for: id)
        } label: { Label("Remove", systemImage: "trash") }
    }

    private func bottomBar(onSelectToday: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            if let toast = viewModel.toast {
                UndoToast(message: toast.message, onUndo: viewModel.undo)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .accessibilityIdentifier("today.toast")
            }
            FloatingTabBar(
                selection: $tab,
                todayProgress: viewModel.isEmpty ? nil : viewModel.todayProgress,
                todayAccessibilityLabel: viewModel.isEmpty ? nil : viewModel.ringAccessibilityLabel,
                onSelectToday: onSelectToday,
                onAdd: { actions.addChecks(viewModel.addTarget) }
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .animation(.snappy, value: viewModel.toast)
    }
}

/// What Today hands back to the root: navigation and sheets it doesn't own.
struct TodayActions {
    /// Opens the Add sheet on a category (Daily when nil).
    var addChecks: (UUID?) -> Void = { _ in }
    var openSettings: () -> Void = {}
    var openCategories: () -> Void = {}
    var openCheck: (UUID) -> Void = { _ in }
    var newCategory: () -> Void = {}
    /// New category on a template's form, filled in; back goes to the gallery.
    var newCategoryFromTemplate: (CategoryTemplate) -> Void = { _ in }
    var editCategory: (UUID) -> Void = { _ in }
}

/// A request to show one category on today; a new one each time, so the same category can be asked for again.
struct CategoryFocus: Equatable {
    let id = UUID()
    let categoryID: UUID
}

/// The check a proof photo is being taken for.
struct PhotoRequest: Identifiable {
    var id: UUID { checkID }
    let checkID: UUID
    let checkName: String
}
