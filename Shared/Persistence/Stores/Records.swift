import Foundation

/// A check as the rest of the app sees it; stores hand these out instead of models.
nonisolated struct CheckRecord: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var kind: CheckKind
    var order: Int
    var categoryID: UUID
    var nudgesOnLeavingHome: Bool
}

/// A category as the rest of the app sees it.
nonisolated struct CategoryRecord: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var icon: CategoryIcon
    var colour: TileSwatch
    var rule: RepeatRule
    /// Minutes after midnight for the reminder, or nil.
    var reminderMinutes: Int?
    var order: Int
    /// Daily: can't be deleted or rescheduled.
    var isDefault: Bool
}

/// A category's details, for creating or editing one.
nonisolated struct CategoryDraft: Hashable, Sendable {
    var name: String
    var icon: CategoryIcon
    var colour: TileSwatch
    var rule: RepeatRule
    var reminderMinutes: Int?

    init(name: String, icon: CategoryIcon = .sun, colour: TileSwatch = .violet, rule: RepeatRule = .daily, reminderMinutes: Int? = nil) {
        self.name = name
        self.icon = icon
        self.colour = colour
        self.rule = rule
        self.reminderMinutes = reminderMinutes
    }
}

/// What happens to a category's tasks when it's deleted (`Plan.md`: ask each time).
nonisolated enum CategoryDeletion: Hashable, Sendable {
    /// Its tasks, their logs and photos go too.
    case deleteTasks
    /// Its tasks move to Daily, keeping their logs.
    case moveTasksToDaily
}

/// One log as the rest of the app sees it.
nonisolated struct LogRecord: Identifiable, Hashable, Sendable {
    let id: UUID
    let checkID: UUID
    var date: Date
    var source: LogSource
    var photoFileName: String?

    var hasPhoto: Bool { photoFileName != nil }
}

/// A new check to add.
nonisolated struct CheckDraft: Hashable, Sendable {
    var name: String
    var kind: CheckKind

    init(name: String, kind: CheckKind? = nil) {
        self.name = name
        self.kind = kind ?? CheckKind.suggested(forName: name)
    }
}

/// What logging did, kept so it can be undone.
nonisolated enum LogOutcome: Hashable, Sendable {
    /// A new log.
    case added(LogRecord)
    /// The same check was logged moments ago, so that log took the new time instead.
    case refreshed(LogRecord, previous: LogRecord)

    var record: LogRecord {
        switch self {
        case .added(let record), .refreshed(let record, _): record
        }
    }
}

nonisolated enum StoreError: Error, Equatable {
    case checkNotFound
    case logNotFound
    case categoryNotFound
    /// A category's name is empty or already used (ignoring case).
    case invalidCategoryName
    /// Daily can't be deleted or rescheduled.
    case defaultCategoryIsFixed
}
