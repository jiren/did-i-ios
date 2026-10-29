import AppIntents
import Foundation

/// "Log front door in Did I?" from Siri, Shortcuts or Spotlight.
struct LogCheckIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a Check"
    static let description = IntentDescription("Records that you just did it, with the time.")

    @Parameter(title: "Check", requestValueDialog: "Which check?")
    var check: CheckEntity

    init() {}

    init(check: CheckEntity) {
        self.check = check
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetIntent {
        let logged = try await CheckLogger.log(check.id, source: .shortcut)
        return .result(dialog: "\(logged.dialog)", snippetIntent: LoggedSnippetIntent(logID: logged.logID))
    }
}

/// A widget or control tap; not offered in Shortcuts.
struct WidgetLogIntent: AppIntent {
    static let title: LocalizedStringResource = "Log from a Widget"
    static let isDiscoverable = false

    @Parameter(title: "Check ID")
    var checkID: String

    @Parameter(title: "Source")
    var sourceRaw: String

    init() {}

    init(checkID: UUID, source: LogSource) {
        self.checkID = checkID.uuidString
        self.sourceRaw = source.rawValue
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: checkID) else { throw IntentError.checkNotFound }
        _ = try await CheckLogger.log(id, source: LogSource(rawValue: sourceRaw) ?? .lockScreenWidget)
        return .result()
    }
}

/// Undo from the Logged snippet.
struct UndoLogIntent: AppIntent {
    static let title: LocalizedStringResource = "Undo a Log"
    static let isDiscoverable = false

    @Parameter(title: "Log ID")
    var logID: String

    init() {}

    init(logID: UUID) {
        self.logID = logID.uuidString
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let id = UUID(uuidString: logID) else { return .result(dialog: "Nothing to undo.") }
        try await CheckLogger.undo(id)
        LoggedSnippetIntent.reload()
        return .result(dialog: "Undone.")
    }
}

/// What a log from outside the app did, for its dialog and snippet.
nonisolated struct LoggedCheck: Sendable {
    let logID: UUID
    let checkName: String
    let kind: CheckKind
    let date: Date
    let source: LogSource
    let timeText: String
    let timeWithSecondsText: String
    let weekdayText: String

    var dialog: String {
        String(localized: "Logged \(checkName) at \(timeText).")
    }
}

/// Logging shared by every intent.
enum CheckLogger {
    @MainActor
    static func log(_ checkID: UUID, source: LogSource) throws -> LoggedCheck {
        let services = IntentServices.shared
        let store = try services.requireStore()
        guard let check = try store.check(id: checkID) else { throw IntentError.checkNotFound }
        let outcome = try store.log(checkID, source: source, at: services.timeSource.now, photoFileName: nil)
        services.afterWrite()
        let time = services.relativeTime
        let date = outcome.record.date
        return LoggedCheck(
            logID: outcome.record.id, checkName: check.name, kind: check.kind, date: date, source: source,
            timeText: time.clockTime(date), timeWithSecondsText: time.clockTimeWithSeconds(date), weekdayText: time.weekday(date)
        )
    }

    @MainActor
    static func undo(_ logID: UUID) throws {
        let services = IntentServices.shared
        if let photo = try? services.requireStore().deleteLog(logID) {
            services.photos.removePhotos(named: [photo])
        }
        services.afterWrite()
    }
}
