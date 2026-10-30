import SwiftUI

/// Places in the app a screen can push to.
enum Route: Hashable {
    case check(UUID)
    case settings
    case actionButton
    case reminders
    case categories
}

/// The Add sheet, opened on a category (Daily when nil).
struct AddChecksRequest: Identifiable {
    let id = UUID()
    let categoryID: UUID?
}

/// The category page: a new category, or one being edited.
enum CategoryEditorRequest: Identifiable, Hashable {
    case new
    case edit(UUID)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let id): id.uuidString
        }
    }
}

/// The app's shell. On compact width, Today or History under one navigation stack; on regular width (iPad),
/// Today or History beside the chosen check's page.
struct RootView: View {
    let environment: AppEnvironment

    @State private var tab: MainTab = .today
    @State private var path: [Route] = []
    /// The Add sheet, with the category it adds to; an item so the sheet always gets this tap's category.
    @State private var addChecks: AddChecksRequest?
    @State private var categoryEditor: CategoryEditorRequest?
    /// Today shown on one category, from a category reminder.
    @State private var categoryFocus: CategoryFocus?
    /// The check shown beside Today on regular width.
    @State private var selectedCheck: UUID?
    @State private var columns: NavigationSplitViewVisibility = .all
    /// The check History opens filtered to, from Detail's "See all in History".
    @State private var historyFilter: UUID?
    /// The Logged screen after an Action Button press that continued in the app.
    @State private var logged: LoggedRequest?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isSplit: Bool { sizeClass == .regular }

    var body: some View {
        shell
            .sheet(item: $addChecks) { request in
                AddChecksSheet(
                    viewModel: AddChecksViewModel(store: environment.store, changes: environment.changes, categoryID: request.categoryID)
                )
            }
            .fullScreenCover(item: $categoryEditor) { request in
                switch request {
                case .new:
                    NewCategoryFlow(
                        templates: CategoryTemplatesViewModel(
                            store: environment.store, days: environment.settings, timeSource: environment.timeSource
                        ),
                        makeEditor: { categoryEditorModel(editing: nil) },
                        onDone: { categoryEditor = nil }
                    )
                case .edit(let id):
                    CategoryEditorView(viewModel: categoryEditorModel(editing: id))
                }
            }
            .fullScreenCover(item: $logged) { request in
                LoggedView(
                    viewModel: LoggedViewModel(
                        request: request,
                        store: environment.store,
                        days: environment.settings,
                        changes: environment.changes,
                        photos: environment.photos
                    ),
                    strongHaptic: environment.settings.actionButtonStrongHaptic
                )
            }
            .environment(environment.changes)
            .task {
                IntentServices.shared.openCheck = { id in
                    logged = nil
                    addChecks = nil
                    open(id, replacing: true)
                }
                IntentServices.shared.openCategory = { id in
                    logged = nil
                    addChecks = nil
                    categoryEditor = nil
                    tab = .today
                    path = []
                    categoryFocus = CategoryFocus(categoryID: id)
                }
                IntentServices.shared.showLogged = { request in
                    addChecks = nil
                    logged = request
                }
                openForDebugging()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { environment.changes.refreshFromDisk() }
            }
    }

    @ViewBuilder
    private var shell: some View {
        if isSplit {
            NavigationSplitView(columnVisibility: $columns) {
                tabContent
                    .navigationSplitViewColumnWidth(min: 360, ideal: 420, max: 520)
            } detail: {
                NavigationStack(path: $path) {
                    Group {
                        if let id = selectedCheck {
                            detail(id, isRoot: true)
                        } else {
                            DetailPlaceholder()
                        }
                    }
                    .id(selectedCheck)
                    .navigationDestination(for: Route.self, destination: destination)
                }
            }
            .navigationSplitViewStyle(.balanced)
        } else {
            NavigationStack(path: $path) {
                tabContent
                    .navigationDestination(for: Route.self, destination: destination)
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .today:
            TodayView(
                viewModel: TodayViewModel(
                    checkStore: environment.store,
                    logStore: environment.store,
                    days: environment.settings,
                    timeSource: environment.timeSource,
                    changes: environment.changes,
                    editor: environment.checkEditor,
                    categoryEditor: environment.categoryEditor,
                    layout: environment.settings,
                    photos: environment.photos
                ),
                tab: $tab,
                focus: categoryFocus,
                actions: TodayActions(
                    addChecks: { category in
                        addChecks = AddChecksRequest(categoryID: category)
                    },
                    openSettings: { isSplit ? (path = [.settings]) : path.append(.settings) },
                    openCategories: { isSplit ? (path = [.categories]) : path.append(.categories) },
                    openCheck: { open($0, replacing: false) },
                    newCategory: { categoryEditor = .new },
                    editCategory: { categoryEditor = .edit($0) }
                )
            )
        case .history:
            HistoryView(
                viewModel: HistoryViewModel(
                    checkStore: environment.store,
                    logStore: environment.store,
                    days: environment.settings,
                    timeSource: environment.timeSource,
                    changes: environment.changes,
                    photos: environment.photos,
                    selectedCheckID: historyFilter
                ),
                tab: $tab,
                onOpenCheck: { open($0, replacing: false) },
                onAddChecks: {
                    addChecks = AddChecksRequest(categoryID: nil)
                }
            )
            .id(historyFilter)
        }
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .check(let id):
            detail(id, isRoot: false)
        case .settings:
            SettingsView(
                viewModel: SettingsViewModel(store: environment.store, changes: environment.changes, photos: environment.photos),
                settings: environment.settings,
                onOpenActionButton: { path.append(.actionButton) },
                onOpenReminders: { path.append(.reminders) }
            )
        case .actionButton:
            let checks = (try? environment.store.checks()) ?? []
            ActionButtonSettingsView(
                settings: environment.settings,
                checks: checks,
                titles: CheckLabels.titles(for: checks, categories: (try? environment.store.categories()) ?? [])
            )
        case .categories:
            CategoriesView(
                viewModel: CategoriesViewModel(
                    store: environment.store, editor: environment.categoryEditor, days: environment.settings,
                    timeSource: environment.timeSource
                ),
                onNew: { categoryEditor = .new },
                onEdit: { categoryEditor = .edit($0) }
            )
        case .reminders:
            RemindersSettingsView(
                viewModel: RemindersSettingsViewModel(
                    settings: environment.settings, store: environment.store, monitor: environment.leaveHome
                )
            )
        }
    }

    private func detail(_ id: UUID, isRoot: Bool) -> some View {
        DetailView(
            viewModel: DetailViewModel(
                checkID: id,
                checkStore: environment.store,
                logStore: environment.store,
                days: environment.settings,
                timeSource: environment.timeSource,
                changes: environment.changes,
                editor: environment.checkEditor,
                photos: environment.photos
            ),
            showsBackButton: !isRoot,
            onSeeAllHistory: { checkID in
                historyFilter = checkID
                path = []
                tab = .history
            },
            onRemoved: { if isRoot { selectedCheck = nil } }
        )
    }

    private func categoryEditorModel(editing id: UUID?) -> CategoryEditorViewModel {
        CategoryEditorViewModel(
            editing: id,
            store: environment.store,
            editor: environment.checkEditor,
            changes: environment.changes,
            days: environment.settings,
            timeSource: environment.timeSource
        )
    }

    /// Opens a check: beside the list on regular width, pushed on compact.
    private func open(_ id: UUID, replacing: Bool) {
        if isSplit {
            selectedCheck = id
            path = []
        } else if replacing {
            path = [.check(id)]
        } else {
            path.append(.check(id))
        }
    }

    private func openForDebugging() {
        #if DEBUG
        switch environment.configuration.debugOpen {
        case "addChecks": addChecks = AddChecksRequest(categoryID: nil)
        case "history": tab = .history
        case "settings": path = [.settings]
        case "actionButton": path = [.settings, .actionButton]
        case "reminders": path = [.settings, .reminders]
        case "categories": path = [.categories]
        case "newCategory": categoryEditor = .new
        case "detail":
            if let first = try? environment.store.checks().first { open(first.id, replacing: true) }
        case "logged":
            if let log = try? environment.store.logs(for: nil, limit: 1).first {
                logged = LoggedRequest(logID: log.id, opensCamera: false)
            }
        default: break
        }
        #endif
    }
}

/// Regular width before a check is chosen.
private struct DetailPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color.tileViolet)
                .accessibilityHidden(true)
            Text("Pick a check to see its history")
                .font(.didSection)
                .foregroundStyle(Color.ink)
            Text("Tap a tile to log it; hold it or choose Details to open it here.")
                .font(.didBody)
                .foregroundStyle(Color.muted)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ground)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}
