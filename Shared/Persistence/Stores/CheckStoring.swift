import Foundation

/// Reads and writes checks. The only code that changes `Check` models.
protocol CheckStoring: AnyObject {
    /// Every check in the whole list's order: category order, then each category's order.
    func checks() throws -> [CheckRecord]
    func check(id: UUID) throws -> CheckRecord?
    /// Adds checks at the end of a category (Daily when nil), skipping empty names and ones that category already
    /// has. Another category may have a task with the same name.
    @discardableResult
    func addChecks(_ drafts: [CheckDraft], to categoryID: UUID?) throws -> [CheckRecord]
    func rename(_ id: UUID, to name: String) throws
    func setKind(_ kind: CheckKind, for id: UUID) throws
    /// Puts the checks in this order; ids left out keep their place after them.
    func reorder(_ ids: [UUID]) throws
    /// Moves a check to the end of another category.
    func moveCheck(_ id: UUID, to categoryID: UUID) throws
    func setNudgesOnLeavingHome(_ isOn: Bool, for id: UUID) throws
    /// Removes the check with its logs, returning the photo file names those logs had.
    @discardableResult
    func removeCheck(_ id: UUID) throws -> [String]
}

extension CheckStoring {
    /// Adds checks to Daily.
    @discardableResult
    func addChecks(_ drafts: [CheckDraft]) throws -> [CheckRecord] {
        try addChecks(drafts, to: nil)
    }
}

/// Reads and writes categories. The only code that changes `CheckCategory` models.
protocol CategoryStoring: AnyObject {
    /// Every category in order, Daily included (created when missing).
    func categories() throws -> [CategoryRecord]
    func category(id: UUID) throws -> CategoryRecord?
    /// Adds a category at the end with its tasks. Throws `invalidCategoryName` for an empty or used name.
    @discardableResult
    func addCategory(_ draft: CategoryDraft, tasks: [CheckDraft]) throws -> CategoryRecord
    /// Changes a category's details; Daily keeps its rule.
    func updateCategory(_ id: UUID, to draft: CategoryDraft) throws
    /// Puts the categories in this order; ids left out keep their place after them.
    func reorderCategories(_ ids: [UUID]) throws
    func setReminder(minutes: Int?, forCategory id: UUID) throws
    /// Deletes a category (never Daily), with its tasks or moving them to Daily. Returns the photo file names of
    /// the logs that went.
    @discardableResult
    func deleteCategory(_ id: UUID, _ deletion: CategoryDeletion) throws -> [String]
}

/// Reads and writes logs. The only code that changes `LogEntry` models.
protocol LogStoring: AnyObject {
    /// Logs a check, or refreshes its last log if that was within `LogRules.refreshWindow`.
    func log(_ checkID: UUID, source: LogSource, at date: Date, photoFileName: String?) throws -> LogOutcome
    /// Reverses a `log` call.
    func undo(_ outcome: LogOutcome) throws
    func setPhoto(_ fileName: String?, forLog id: UUID) throws
    /// Deletes one log, returning its photo file name.
    @discardableResult
    func deleteLog(_ id: UUID) throws -> String?
    /// Newest first, for one check or all of them.
    func logs(for checkID: UUID?, limit: Int?) throws -> [LogRecord]
    /// Logs from `start` (inclusive) to `end` (exclusive), newest first.
    func logs(from start: Date, to end: Date) throws -> [LogRecord]
    /// The newest log of each check that has one.
    func latestLogs() throws -> [UUID: LogRecord]
    func logCount(for checkID: UUID) throws -> Int
    /// Every photo file name a log still points at.
    func photoFileNames() throws -> Set<String>
    /// Removes the photo from logs older than `date`, returning those file names.
    @discardableResult
    func clearPhotos(olderThan date: Date) throws -> [String]
    /// Removes every log but keeps the checks, returning the photo file names.
    @discardableResult
    func deleteAllLogs() throws -> [String]
    /// Removes every category, check and log (Daily comes back empty), returning their photo file names.
    @discardableResult
    func deleteEverything() throws -> [String]
}

nonisolated enum LogRules {
    /// Logging the same check again within this many seconds refreshes the last log instead of adding one.
    static let refreshWindow: TimeInterval = 10
}
