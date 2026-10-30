import AppIntents
import Foundation

/// A check, for Siri, Shortcuts, Spotlight, widgets and the Action Button.
struct CheckEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Check")
    static let defaultQuery = CheckEntityQuery()

    let id: UUID
    let name: String
    let kind: CheckKind
    /// Its category's name, shown under it so two "Stove off"s can be told apart.
    let category: String?

    init(_ record: CheckRecord, category: String? = nil) {
        id = record.id
        name = record.name
        kind = record.kind
        self.category = category
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: category.map { "\($0)" },
            image: .init(systemName: kind.symbolName)
        )
    }

    /// Every check as an entity, with its category, in the store's order.
    @MainActor
    static func all(from store: some CheckStoring & CategoryStoring) throws -> [CheckEntity] {
        let names = Dictionary(try store.categories().map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        return try store.checks().map { CheckEntity($0, category: names[$0.categoryID]) }
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
        try CheckEntity.all(from: IntentServices.shared.requireStore())
    }

    @MainActor
    private func dueFirst() throws -> [CheckEntity] {
        let services = IntentServices.shared
        let checks = try CheckEntity.all(from: services.requireStore())
        let due = try services.dueIDs(on: services.timeSource.now)
        return checks.filter { due.contains($0.id) } + checks.filter { !due.contains($0.id) }
    }
}
