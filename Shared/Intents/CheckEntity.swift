import AppIntents
import Foundation

/// A check, for Siri, Shortcuts, Spotlight, widgets and the Action Button.
struct CheckEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Check")
    static let defaultQuery = CheckEntityQuery()

    let id: UUID
    let name: String
    let kind: CheckKind

    init(_ record: CheckRecord) {
        id = record.id
        name = record.name
        kind = record.kind
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: kind.symbolName))
    }
}

struct CheckEntityQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [CheckEntity] {
        try await allChecks().filter { identifiers.contains($0.id) }
    }

    /// Today's due tasks first, for "Ask me which" and Siri's list.
    func suggestedEntities() async throws -> [CheckEntity] {
        try await dueFirst()
    }

    func entities(matching string: String) async throws -> [CheckEntity] {
        let words = string.lowercased().split(separator: " ")
        return try await allChecks().filter { check in
            let name = check.name.lowercased()
            return words.allSatisfy { name.contains($0) }
        }
    }

    @MainActor
    private func allChecks() throws -> [CheckEntity] {
        try IntentServices.shared.requireStore().checks().map(CheckEntity.init)
    }

    @MainActor
    private func dueFirst() throws -> [CheckEntity] {
        let services = IntentServices.shared
        let checks = try services.requireStore().checks()
        let due = try services.dueIDs(on: services.timeSource.now)
        return (checks.filter { due.contains($0.id) } + checks.filter { !due.contains($0.id) }).map(CheckEntity.init)
    }
}
