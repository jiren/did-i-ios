import SwiftUI

/// Places in the app a screen can push to.
enum Route: Hashable {
    case check(UUID)
    case settings
    case actionButton
    case reminders
}

/// The app's shell. On compact width, Today or History under one navigation stack; on regular width (iPad),
/// Today or History beside the chosen check's page.
struct RootView: View {
    let environment: AppEnvironment

    @State private var tab: MainTab = .today
    @State private var path: [Route] = []
    @State private var isAddingChecks = false
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
            .sheet(isPresented: $isAddingChecks) {
                AddChecksSheet(viewModel: AddChecksViewModel(store: environment.store, changes: environment.changes))
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
                    isAddingChecks = false
                    open(id, replacing: true)
                }
                IntentServices.shared.showLogged = { request in
                    isAddingChecks = false
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
                    photos: environment.photos
                ),
                tab: $tab,
                actions: TodayActions(
                    addChecks: { isAddingChecks = true },
                    openSettings: { isSplit ? (path = [.settings]) : path.append(.settings) },
                    openCheck: { open($0, replacing: false) },
                    seeAll: {
                        historyFilter = nil
                        tab = .history
                    }
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
                onAddChecks: { isAddingChecks = true }
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
            ActionButtonSettingsView(settings: environment.settings, checks: (try? environment.store.checks()) ?? [])
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
        case "addChecks": isAddingChecks = true
        case "history": tab = .history
        case "settings": path = [.settings]
        case "actionButton": path = [.settings, .actionButton]
        case "reminders": path = [.settings, .reminders]
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
