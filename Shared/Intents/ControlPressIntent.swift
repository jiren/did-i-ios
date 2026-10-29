import AppIntents
import Foundation

/// The Did I? control in Control Center, or on the Action Button: the same as an Action Button press,
/// logged as coming from the control.
struct ControlPressIntent: AppIntent {
    static let title: LocalizedStringResource = "Log with the Did I? Control"
    static let isDiscoverable = false
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    @Parameter(title: "Check")
    var check: CheckEntity?

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetIntent {
        let checkID = try await PressResolver.checkID(chosen: check, parameter: $check)
        let logged = try await CheckLogger.log(checkID, source: .control)
        if await IntentServices.shared.settings.actionButtonOpensCamera {
            try await continueInForeground(alwaysConfirm: false)
            await IntentServices.shared.showLogged?(LoggedRequest(logID: logged.logID, opensCamera: true))
        }
        return .result(dialog: "\(logged.dialog)", snippetIntent: LoggedSnippetIntent(logID: logged.logID))
    }
}

/// Which check a press logs: the one picked in Settings, else the parameter, else ask.
enum PressResolver {
    static func checkID(chosen: CheckEntity?, parameter: IntentParameter<CheckEntity?>) async throws -> UUID {
        let checks = try await CheckEntityQuery().suggestedEntities()
        if let picked = IntentServices.shared.settings.actionButtonCheckID, checks.contains(where: { $0.id == picked }) {
            return picked
        }
        if let chosen { return chosen.id }
        guard !checks.isEmpty else { throw ActionButtonError.noChecks }
        if checks.count == 1, let only = checks.first { return only.id }
        return try await parameter.requestDisambiguation(among: checks, dialog: "Which check?").id
    }
}
