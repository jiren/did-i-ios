import AppIntents
import Foundation

/// What a press of the Action Button (or the Did I? control) does: logs the check picked in
/// Settings › Action Button, or asks which. With Open camera on, it continues in the app.
struct ActionButtonPressIntent: AppIntent {
    static let title: LocalizedStringResource = "Log with the Action Button"
    static let description = IntentDescription("Logs the check you picked in Did I? › Settings › Action Button, or asks which.")
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    @Parameter(title: "Check")
    var check: CheckEntity?

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetIntent {
        let checkID = try await PressResolver.checkID(chosen: check, parameter: $check)
        let logged = try await CheckLogger.log(checkID, source: .actionButton)
        if await IntentServices.shared.settings.actionButtonOpensCamera {
            try await continueInForeground(alwaysConfirm: false)
            await IntentServices.shared.showLogged?(LoggedRequest(logID: logged.logID, opensCamera: true))
        }
        return .result(dialog: "\(logged.dialog)", snippetIntent: LoggedSnippetIntent(logID: logged.logID))
    }
}

nonisolated enum ActionButtonError: Error, CustomLocalizedStringResourceConvertible {
    case noChecks

    var localizedStringResource: LocalizedStringResource {
        "Add a check in Did I? first."
    }
}

/// Opens the app on a log's Logged screen, e.g. to add a photo from the snippet.
struct OpenLoggedIntent: AppIntent {
    static let title: LocalizedStringResource = "Add a Photo to a Log"
    static let isDiscoverable = false
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Log ID")
    var logID: String

    init() {}

    init(logID: UUID) {
        self.logID = logID.uuidString
    }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: logID) {
            await IntentServices.shared.showLogged?(LoggedRequest(logID: id, opensCamera: true))
        }
        return .result()
    }
}
