import AppIntents
import SwiftUI

/// The interactive card shown after a log from Siri, Shortcuts or the Action Button (`Logged.dc.html`):
/// the check and time, with Undo and Add a photo.
struct LoggedSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Logged"
    static let isDiscoverable = false

    @Parameter(title: "Log ID")
    var logID: String

    init() {}

    init(logID: UUID) {
        self.logID = logID.uuidString
    }

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let content = await Self.content(for: UUID(uuidString: logID))
        return .result(view: LoggedSnippetView(content: content))
    }

    @MainActor
    private static func content(for logID: UUID?) -> LoggedSnippetView.Content {
        let services = IntentServices.shared
        guard let logID, let store = services.store,
              let log = try? store.logs(for: nil, limit: 200).first(where: { $0.id == logID }),
              let check = try? store.check(id: log.checkID) else {
            return .undone
        }
        let time = services.relativeTime
        return .logged(
            logID: logID,
            title: String(localized: "\(check.name)."),
            when: String(localized: "\(time.weekday(log.date)) · \(time.clockTimeWithSeconds(log.date))"),
            source: log.source.label(hasPhoto: log.hasPhoto)
        )
    }
}

struct LoggedSnippetView: View {
    enum Content: Equatable {
        case logged(logID: UUID, title: String, when: String, source: String)
        case undone
    }

    let content: Content

    var body: some View {
        switch content {
        case .logged(let logID, let title, let when, let source):
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(Color.onTile)
                        .frame(width: 44, height: 44)
                        .background(Color.tileSun, in: .circle)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.didSection).foregroundStyle(.white)
                        Text(when).font(.didSubheadline).foregroundStyle(Color.tileVioletSub)
                        Text(source).font(.didFootnote).foregroundStyle(Color.tileVioletSub)
                    }
                }
                HStack(spacing: 10) {
                    Button(intent: UndoLogIntent(logID: logID)) { Text("Undo").frame(maxWidth: .infinity) }
                        .buttonStyle(PillButtonStyle(variant: .outline, height: 48))
                    Button(intent: OpenLoggedIntent(logID: logID)) {
                        Label("Add a photo", systemImage: "camera.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(variant: .light, height: 48))
                }
            }
            .padding(16)
            .background(Color.tileViolet, in: .rect(cornerRadius: 26, style: .continuous))
        case .undone:
            Text("Undone. Nothing was logged.")
                .font(.didRowTitle)
                .foregroundStyle(Color.ink)
                .padding(16)
        }
    }
}
