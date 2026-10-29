import AppIntents
import Foundation

/// Opens Did I? on a check's page (Spotlight and Shortcuts).
struct OpenCheckIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open a Check"

    @Parameter(title: "Check")
    var target: CheckEntity

    init() {}

    func perform() async throws -> some IntentResult {
        await IntentServices.shared.openCheck?(target.id)
        return .result()
    }
}
