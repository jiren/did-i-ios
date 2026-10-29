import Foundation

/// Reads and writes checks. The only code that changes `Check` models.
protocol CheckStoring: AnyObject {
    /// Every check in Today's order.
    func checks() throws -> [CheckRecord]
    func check(id: UUID) throws -> CheckRecord?
    /// Adds checks at the end, skipping empty names and ones that already exist.
    @discardableResult
    func addChecks(_ drafts: [CheckDraft]) throws -> [CheckRecord]
    func rename(_ id: UUID, to name: String) throws
    func setKind(_ kind: CheckKind, for id: UUID) throws
    /// Puts the checks in this order; ids left out keep their place after them.
    func reorder(_ ids: [UUID]) throws
    func setReminder(minutes: Int?, for id: UUID) throws
    func setNudgesOnLeavingHome(_ isOn: Bool, for id: UUID) throws
    /// Removes the check with its logs, returning the photo file names those logs had.
    @discardableResult
    func removeCheck(_ id: UUID) throws -> [String]
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
    /// Removes every check and log, returning their photo file names.
    @discardableResult
    func deleteEverything() throws -> [String]
}

nonisolated enum LogRules {
    /// Logging the same check again within this many seconds refreshes the last log instead of adding one.
    static let refreshWindow: TimeInterval = 10
}
