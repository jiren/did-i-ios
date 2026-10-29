import Foundation
import SwiftData

/// Checks and logs in SwiftData. Hands out records, never models, so its context can be replaced when another
/// process (the widget extension) has written to the same store.
final class SwiftDataStore: CheckStoring, LogStoring {
    private let container: ModelContainer
    private var context: ModelContext
    private let timeSource: any TimeSource

    init(container: ModelContainer, timeSource: any TimeSource = SystemTimeSource()) {
        self.container = container
        self.timeSource = timeSource
        self.context = Self.makeContext(container)
    }

    private static func makeContext(_ container: ModelContainer) -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    /// Drops cached models so the next read sees what other processes wrote.
    func reloadFromDisk() {
        context = Self.makeContext(container)
    }

    // MARK: - Checks

    func checks() throws -> [CheckRecord] {
        try allCheckModels().map { Self.record($0) }
    }

    func check(id: UUID) throws -> CheckRecord? {
        try checkModel(id).map { Self.record($0) }
    }

    @discardableResult
    func addChecks(_ drafts: [CheckDraft]) throws -> [CheckRecord] {
        let existing = try allCheckModels()
        var keys = Set(existing.map { CheckName.key($0.name) })
        var order = (existing.map(\.order).max() ?? -1) + 1
        var added: [Check] = []
        for draft in drafts {
            guard let name = CheckName.cleaned(draft.name), keys.insert(CheckName.key(name)).inserted else { continue }
            let check = Check(name: name, kind: draft.kind, order: order, now: timeSource.now)
            context.insert(check)
            added.append(check)
            order += 1
        }
        try context.save()
        return added.map { Self.record($0) }
    }

    func rename(_ id: UUID, to name: String) throws {
        guard let cleaned = CheckName.cleaned(name) else { return }
        try update(id) { $0.name = cleaned }
    }

    func setKind(_ kind: CheckKind, for id: UUID) throws {
        try update(id) { $0.kindRaw = kind.rawValue }
    }

    func reorder(_ ids: [UUID]) throws {
        let models = try allCheckModels()
        let position = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($1, $0) })
        let sorted = models.sorted {
            (position[$0.id] ?? ids.count + $0.order, $0.order) < (position[$1.id] ?? ids.count + $1.order, $1.order)
        }
        for (index, model) in sorted.enumerated() where model.order != index {
            model.order = index
            model.updatedAt = timeSource.now
        }
        try context.save()
    }

    func setReminder(minutes: Int?, for id: UUID) throws {
        try update(id) { $0.reminderMinutes = minutes.map { min(max($0, 0), 24 * 60 - 1) } }
    }

    func setNudgesOnLeavingHome(_ isOn: Bool, for id: UUID) throws {
        try update(id) { $0.nudgesOnLeavingHome = isOn }
    }

    @discardableResult
    func removeCheck(_ id: UUID) throws -> [String] {
        guard let model = try checkModel(id) else { throw StoreError.checkNotFound }
        let photos = model.logs.compactMap(\.photoFileName)
        context.delete(model)
        try context.save()
        return photos
    }

    // MARK: - Logs

    func log(_ checkID: UUID, source: LogSource, at date: Date, photoFileName: String?) throws -> LogOutcome {
        guard let check = try checkModel(checkID) else { throw StoreError.checkNotFound }
        if let latest = try latestLogModel(for: checkID),
           abs(date.timeIntervalSince(latest.date)) < LogRules.refreshWindow {
            let previous = Self.record(latest)
            latest.date = max(latest.date, date)
            latest.sourceRaw = source.rawValue
            if let photoFileName { latest.photoFileName = photoFileName }
            latest.updatedAt = timeSource.now
            try context.save()
            return .refreshed(Self.record(latest), previous: previous)
        }
        let entry = LogEntry(date: date, source: source, photoFileName: photoFileName, check: check)
        context.insert(entry)
        check.updatedAt = timeSource.now
        try context.save()
        return .added(Self.record(entry))
    }

    func undo(_ outcome: LogOutcome) throws {
        switch outcome {
        case .added(let record):
            try deleteLog(record.id)
        case .refreshed(_, let previous):
            guard let entry = try logModel(previous.id) else { throw StoreError.logNotFound }
            entry.date = previous.date
            entry.sourceRaw = previous.source.rawValue
            entry.photoFileName = previous.photoFileName
            entry.updatedAt = timeSource.now
            try context.save()
        }
    }

    func setPhoto(_ fileName: String?, forLog id: UUID) throws {
        guard let entry = try logModel(id) else { throw StoreError.logNotFound }
        entry.photoFileName = fileName
        entry.updatedAt = timeSource.now
        try context.save()
    }

    @discardableResult
    func deleteLog(_ id: UUID) throws -> String? {
        guard let entry = try logModel(id) else { throw StoreError.logNotFound }
        let photo = entry.photoFileName
        entry.check?.updatedAt = timeSource.now
        context.delete(entry)
        try context.save()
        return photo
    }

    func logs(for checkID: UUID?, limit: Int?) throws -> [LogRecord] {
        var descriptor = FetchDescriptor<LogEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        if let checkID {
            descriptor.predicate = #Predicate { $0.check?.id == checkID }
        }
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor).map { Self.record($0) }
    }

    func logs(from start: Date, to end: Date) throws -> [LogRecord] {
        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).map { Self.record($0) }
    }

    func latestLogs() throws -> [UUID: LogRecord] {
        var latest: [UUID: LogRecord] = [:]
        for check in try allCheckModels() {
            if let entry = try latestLogModel(for: check.id) {
                latest[check.id] = Self.record(entry)
            }
        }
        return latest
    }

    func logCount(for checkID: UUID) throws -> Int {
        try context.fetchCount(FetchDescriptor<LogEntry>(predicate: #Predicate { $0.check?.id == checkID }))
    }

    func photoFileNames() throws -> Set<String> {
        let descriptor = FetchDescriptor<LogEntry>(predicate: #Predicate { $0.photoFileName != nil })
        return Set(try context.fetch(descriptor).compactMap(\.photoFileName))
    }

    @discardableResult
    func clearPhotos(olderThan date: Date) throws -> [String] {
        let descriptor = FetchDescriptor<LogEntry>(predicate: #Predicate { $0.photoFileName != nil && $0.date < date })
        let entries = try context.fetch(descriptor)
        let names = entries.compactMap(\.photoFileName)
        for entry in entries {
            entry.photoFileName = nil
            entry.updatedAt = timeSource.now
        }
        try context.save()
        return names
    }

    @discardableResult
    func deleteEverything() throws -> [String] {
        let photos = Array(try photoFileNames())
        try context.delete(model: LogEntry.self)
        try context.delete(model: Check.self)
        try context.save()
        return photos
    }

    // MARK: - Models

    private func allCheckModels() throws -> [Check] {
        try context.fetch(FetchDescriptor<Check>(sortBy: [SortDescriptor(\.order), SortDescriptor(\.createdAt)]))
    }

    private func checkModel(_ id: UUID) throws -> Check? {
        var descriptor = FetchDescriptor<Check>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func logModel(_ id: UUID) throws -> LogEntry? {
        var descriptor = FetchDescriptor<LogEntry>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func latestLogModel(for checkID: UUID) throws -> LogEntry? {
        var descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate { $0.check?.id == checkID },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func update(_ id: UUID, _ change: (Check) -> Void) throws {
        guard let model = try checkModel(id) else { throw StoreError.checkNotFound }
        change(model)
        model.updatedAt = timeSource.now
        try context.save()
    }

    private static func record(_ model: Check) -> CheckRecord {
        CheckRecord(
            id: model.id,
            name: model.name,
            kind: CheckKind(rawValue: model.kindRaw) ?? .other,
            order: model.order,
            reminderMinutes: model.reminderMinutes,
            nudgesOnLeavingHome: model.nudgesOnLeavingHome
        )
    }

    private static func record(_ model: LogEntry) -> LogRecord {
        LogRecord(
            id: model.id,
            checkID: model.check?.id ?? UUID(),
            date: model.date,
            source: LogSource(rawValue: model.sourceRaw) ?? .app,
            photoFileName: model.photoFileName
        )
    }
}
