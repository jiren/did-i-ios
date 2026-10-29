import SwiftUI

/// Places in the app a screen can push to.
enum Route: Hashable {
    case check(UUID)
    case settings
}

/// The app's shell: Today or History under one navigation stack, with the sheets they open.
struct RootView: View {
    let environment: AppEnvironment

    @State private var tab: MainTab = .today
    @State private var path: [Route] = []
    @State private var isAddingChecks = false
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
                    PlaceholderScreen(title: String(localized: "History"), tab: $tab, onAdd: { isAddingChecks = true })
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .check:
                    PlaceholderScreen(title: String(localized: "Check"), tab: nil, onAdd: {})
                case .settings:
                    PlaceholderScreen(title: String(localized: "Settings"), tab: nil, onAdd: {})
                }
            }
        }
        .sheet(isPresented: $isAddingChecks) {
            AddChecksSheet(viewModel: AddChecksViewModel(store: environment.store, changes: environment.changes))
        }
        .environment(environment.changes)
        .task { openForDebugging() }
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
            seeAll: { tab = .history }
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
