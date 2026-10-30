import AppIntents
import Foundation

/// "Did I lock the front door?" — answered from the latest log.
struct LastLogIntent: AppIntent {
    static let title: LocalizedStringResource = "Did I Do It?"
    static let description = IntentDescription("Tells you when you last logged a check.")

    @Parameter(title: "Check", requestValueDialog: "Which check?")
    var check: CheckEntity

    init() {}

    init(check: CheckEntity) {
        self.check = check
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let answer = try await Self.answer(for: check.id)
        return .result(value: answer, dialog: "\(answer)")
    }

    @MainActor
    private static func answer(for checkID: UUID) throws -> String {
        let services = IntentServices.shared
        let store = try services.requireStore()
        guard let check = try store.check(id: checkID) else { throw IntentError.checkNotFound }
        let latest = try store.logs(for: checkID, limit: 1).first?.date
        let now = services.timeSource.now
        return LastLogAnswer.text(
            checkName: check.name, latest: latest, now: now, time: services.relativeTime,
            isDueToday: try services.dueIDs(on: now).contains(checkID)
        )
    }
}
