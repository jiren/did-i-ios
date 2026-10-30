import Foundation

/// What a widget shows for one check, read from the shared store.
nonisolated struct WidgetCheck: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let kind: CheckKind
    let swatch: TileSwatch
    /// Today's latest log, if any.
    let loggedToday: Date?
    /// Its category is due today, and tomorrow (for the timeline's next-day entry).
    var isDueToday = true
    var isDueTomorrow = true

    /// The same check at the next day's start: not logged, due as tomorrow says.
    var nextDay: WidgetCheck {
        WidgetCheck(id: id, name: name, kind: kind, swatch: swatch, loggedToday: nil, isDueToday: isDueTomorrow, isDueTomorrow: isDueTomorrow)
    }
}

/// The widgets' view of the store at one moment.
nonisolated struct WidgetSnapshot: Sendable {
    let checks: [WidgetCheck]
    let hidesNames: Bool
    /// When "today" ends, so the timeline can turn tiles back to "not yet".
    let nextDayStart: Date

    /// The tasks due today, in the whole list's order, for the overview widget.
    var dueToday: [WidgetCheck] { checks.filter(\.isDueToday) }

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
    static func read(services: IntentServices, now: Date, boundary: DayBoundary? = nil) -> WidgetSnapshot {
        let boundary = boundary ?? services.settings.dayBoundary
        let records = (try? services.store?.checks()) ?? []
        let categories = (try? services.store?.categories()) ?? []
        let latest = (try? services.store?.latestLogs()) ?? [:]
        let today = boundary.calendarDay(containing: now)
        let dueToday = DueTasks.ids(on: today, categories: categories, checks: records, calendar: boundary.calendar)
        let dueTomorrow = DueTasks.ids(
            on: today.adding(days: 1, calendar: boundary.calendar), categories: categories, checks: records, calendar: boundary.calendar
        )
        let checks = records.enumerated().map { position, check in
            WidgetCheck(
                id: check.id,
                name: check.name,
                kind: check.kind,
                swatch: TileSwatch.at(position: position),
                loggedToday: latest[check.id].flatMap { boundary.isInSameDay($0.date, as: now) ? $0.date : nil },
                isDueToday: dueToday.contains(check.id),
                isDueTomorrow: dueTomorrow.contains(check.id)
            )
        }
        return WidgetSnapshot(
            checks: checks,
            hidesNames: services.settings.hidesNamesOnLockScreen,
            nextDayStart: boundary.day(containing: now).end
        )
    }
}
