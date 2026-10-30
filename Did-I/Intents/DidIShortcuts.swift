import AppIntents
import CoreSpotlight

/// Siri phrases and Spotlight actions, available as soon as the app is installed.
struct DidIShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LastLogIntent(),
            phrases: [
                "\(.applicationName) \(\.$check)",
                "Ask \(.applicationName) about \(\.$check)",
                "Check \(\.$check) in \(.applicationName)",
            ],
            shortTitle: "Did I?",
            systemImageName: "questionmark.circle"
        )
        AppShortcut(
            intent: LogCheckIntent(),
            phrases: [
                "Log \(\.$check) in \(.applicationName)",
                "\(.applicationName) log \(\.$check)",
            ],
            shortTitle: "Log a Check",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: ActionButtonPressIntent(),
            phrases: ["Log with \(.applicationName)"],
            shortTitle: "Action Button Press",
            systemImageName: "button.vertical.right.press"
        )
    }
}

/// Keeps Siri's phrase parameters and Spotlight in step with the checks.
enum ShortcutsIndex {
    static func update(from store: SwiftDataStore) {
        DidIShortcuts.updateAppShortcutParameters()
        let entities = (try? CheckEntity.all(from: store)) ?? []
        Task {
            try? await CSSearchableIndex.default().deleteAppEntities(ofType: CheckEntity.self)
            try? await CSSearchableIndex.default().indexAppEntities(entities)
        }
    }
}
