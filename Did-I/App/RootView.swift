import SwiftUI

/// Places in the app a screen can push to.
enum Route: Hashable {
    case check(UUID)
    case settings
    case actionButton
    case reminders
}

/// The app's shell: Today or History under one navigation stack, with the sheets they open.
struct RootView: View {
    let environment: AppEnvironment

    @State private var tab: MainTab = .today
    @State private var path: [Route] = []
    @State private var isAddingChecks = false
    /// The check History opens filtered to, from Detail's "See all in History".
    @State private var historyFilter: UUID?
    /// The Logged screen after an Action Button press that continued in the app.
    @State private var logged: LoggedRequest?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack(path: $path) {
            Group {
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
                        actions: todayActions
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
                        onOpenCheck: { path.append(.check($0)) },
                        onAddChecks: { isAddingChecks = true }
                    )
                    .id(historyFilter)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .check(let id):
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
                        onSeeAllHistory: { checkID in
                            historyFilter = checkID
                            path = []
                            tab = .history
                        }
                    )
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
                    PlaceholderScreen(title: String(localized: "Reminders"), tab: nil, onAdd: {})
                }
            }
        }
        .sheet(isPresented: $isAddingChecks) {
            AddChecksSheet(viewModel: AddChecksViewModel(store: environment.store, changes: environment.changes))
        }
        .environment(environment.changes)
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
        .task {
            IntentServices.shared.openCheck = { id in
                logged = nil
                isAddingChecks = false
                path = [.check(id)]
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

    private func openForDebugging() {
        #if DEBUG
        switch environment.configuration.debugOpen {
        case "addChecks": isAddingChecks = true
        case "history": tab = .history
        case "settings": path = [.settings]
        case "actionButton": path = [.settings, .actionButton]
        case "logged":
            if let log = try? environment.store.logs(for: nil, limit: 1).first {
                logged = LoggedRequest(logID: log.id, opensCamera: false)
            }
        case "detail":
            if let first = try? environment.store.checks().first { path = [.check(first.id)] }
        default: break
        }
        #endif
    }

    private var todayActions: TodayActions {
        TodayActions(
            addChecks: { isAddingChecks = true },
            openSettings: { path.append(.settings) },
            openCheck: { path.append(.check($0)) },
            seeAll: {
                historyFilter = nil
                tab = .history
            }
        )
    }
}

/// Stands in for a screen a later phase builds.
private struct PlaceholderScreen: View {
    let title: String
    let tab: Binding<MainTab>?
    let onAdd: () -> Void

    var body: some View {
        Text(title)
            .font(.didScreenTitle)
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.ground)
            .safeAreaInset(edge: .bottom) {
                if let tab {
                    FloatingTabBar(selection: tab, onAdd: onAdd).padding(.horizontal, 20).padding(.bottom, 8)
                }
            }
    }
}
