import Foundation

/// What a widget shows for one check, read from the shared store.
nonisolated struct WidgetCheck: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let kind: CheckKind
    let swatch: TileSwatch
    /// Today's latest log, if any.
    let loggedToday: Date?
}

/// The widgets' view of the store at one moment.
nonisolated struct WidgetSnapshot: Sendable {
    let checks: [WidgetCheck]
    let hidesNames: Bool
    /// When "today" ends, so the timeline can turn tiles back to "not yet".
    let nextDayStart: Date

    static let placeholder = WidgetSnapshot(
        checks: [
            WidgetCheck(id: UUID(), name: String(localized: "Front door locked"), kind: .door, swatch: .violet, loggedToday: Date()),
            WidgetCheck(id: UUID(), name: String(localized: "Pill taken"), kind: .pill, swatch: .sun, loggedToday: Date()),
            WidgetCheck(id: UUID(), name: String(localized: "Stove off"), kind: .stove, swatch: .coral, loggedToday: nil),
            WidgetCheck(id: UUID(), name: String(localized: "Iron unplugged"), kind: .plug, swatch: .mint, loggedToday: nil),
        ],
        hidesNames: false,
        nextDayStart: Date().addingTimeInterval(86_400)
    )

    @MainActor
    static func read(services: IntentServices, now: Date) -> WidgetSnapshot {
        let boundary = services.settings.dayBoundary
        let records = (try? services.store?.checks()) ?? []
        let latest = (try? services.store?.latestLogs()) ?? [:]
        let checks = records.enumerated().map { position, check in
            WidgetCheck(
                id: check.id,
                name: check.name,
                kind: check.kind,
                swatch: TileSwatch.at(position: position),
                loggedToday: latest[check.id].flatMap { boundary.isInSameDay($0.date, as: now) ? $0.date : nil }
            )
        }
        return WidgetSnapshot(
            checks: checks,
            hidesNames: services.settings.hidesNamesOnLockScreen,
            nextDayStart: boundary.day(containing: now).end
        )
    }
}
