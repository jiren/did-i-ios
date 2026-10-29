import Foundation

/// A check as the rest of the app sees it; stores hand these out instead of models.
nonisolated struct CheckRecord: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var kind: CheckKind
    var order: Int
    /// Minutes after midnight for the daily reminder, or nil.
    var reminderMinutes: Int?
    var nudgesOnLeavingHome: Bool
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
}
