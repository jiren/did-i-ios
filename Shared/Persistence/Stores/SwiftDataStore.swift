import Foundation
import SwiftData

/// Categories, checks and logs in SwiftData. Hands out records, never models, so its context can be replaced when another
/// process (the widget extension) has written to the same store.
final class SwiftDataStore: CheckStoring, CategoryStoring, LogStoring {
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
    func addChecks(_ drafts: [CheckDraft], to categoryID: UUID?) throws -> [CheckRecord] {
        let category = try existingCategoryModel(categoryID ?? CategoryDefaults.dailyID)
        let added = try insertChecks(drafts, into: category)
        try context.save()
        return added.map { Self.record($0) }
    }

    /// Inserts checks at the end of `category` without saving. Names are unique within a category; another
    /// category can have a task with the same name.
    private func insertChecks(_ drafts: [CheckDraft], into category: CheckCategory) throws -> [Check] {
        let existing = try allCheckModels()
        var keys = Set(existing.filter { $0.category?.id == category.id }.map { CheckName.key($0.name) })
        var order = (existing.map(\.order).max() ?? -1) + 1
        var added: [Check] = []
        for draft in drafts {
            guard let name = CheckName.cleaned(draft.name), keys.insert(CheckName.key(name)).inserted else { continue }
            let check = Check(name: name, kind: draft.kind, order: order, category: category, now: timeSource.now)
            context.insert(check)
            added.append(check)
            order += 1
        }
        if !added.isEmpty { category.updatedAt = timeSource.now }
        return added
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

    func moveCheck(_ id: UUID, to categoryID: UUID) throws {
        let category = try existingCategoryModel(categoryID)
        let order = (try allCheckModels().map(\.order).max() ?? -1) + 1
        try update(id) { check in
            guard check.category?.id != categoryID else { return }
            check.category = category
            check.order = order
            category.updatedAt = timeSource.now
        }
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

    // MARK: - Categories

    func categories() throws -> [CategoryRecord] {
        var models = try allCategoryModels()
        if !models.contains(where: \.isDefault) {
            _ = try dailyModel()
            try context.save()
            models = try allCategoryModels()
        }
        return models.map { Self.record($0) }
    }

    func category(id: UUID) throws -> CategoryRecord? {
        if id == CategoryDefaults.dailyID {
            let daily = try dailyModel()
            if context.hasChanges { try context.save() }
            return Self.record(daily)
        }
        return try categoryModel(id).map { Self.record($0) }
    }

    @discardableResult
    func addCategory(_ draft: CategoryDraft, tasks: [CheckDraft]) throws -> CategoryRecord {
        _ = try dailyModel()
        let name = try validatedName(draft.name, excluding: nil)
        let order = (try allCategoryModels().map(\.order).max() ?? -1) + 1
        let category = CheckCategory(name: name, icon: draft.icon, colour: draft.colour, rule: draft.rule, order: order, now: timeSource.now)
        category.reminderMinutes = Self.clampedMinutes(draft.reminderMinutes)
        context.insert(category)
        _ = try insertChecks(tasks, into: category)
        try context.save()
        return Self.record(category)
    }

    func updateCategory(_ id: UUID, to draft: CategoryDraft) throws {
        let name = try validatedName(draft.name, excluding: id)
        try updateCategory(id) { category in
            if category.isDefault, draft.rule != .daily { throw StoreError.defaultCategoryIsFixed }
            category.name = name
            category.iconRaw = draft.icon.rawValue
            category.colourRaw = draft.colour.key
            if category.rule != draft.rule { category.rule = draft.rule }
            category.reminderMinutes = Self.clampedMinutes(draft.reminderMinutes)
        }
    }

    func reorderCategories(_ ids: [UUID]) throws {
        let models = try allCategoryModels()
        let position = Dictionary(ids.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        let sorted = models.sorted {
            (position[$0.id] ?? ids.count + $0.order, $0.order) < (position[$1.id] ?? ids.count + $1.order, $1.order)
        }
        for (index, model) in sorted.enumerated() where model.order != index {
            model.order = index
            model.updatedAt = timeSource.now
        }
        try context.save()
    }

    func setReminder(minutes: Int?, forCategory id: UUID) throws {
        try updateCategory(id) { $0.reminderMinutes = Self.clampedMinutes(minutes) }
    }

    @discardableResult
    func deleteCategory(_ id: UUID, _ deletion: CategoryDeletion) throws -> [String] {
        guard let category = try categoryModel(id) else { throw StoreError.categoryNotFound }
        guard !category.isDefault else { throw StoreError.defaultCategoryIsFixed }
        var photos: [String] = []
        switch deletion {
        case .deleteTasks:
            // Their logs go with them (cascade).
            for check in category.checks {
                photos += check.logs.compactMap(\.photoFileName)
                context.delete(check)
            }
        case .moveTasksToDaily:
            let daily = try dailyModel()
            var order = (try allCheckModels().map(\.order).max() ?? -1) + 1
            for check in category.checks.sorted(by: { $0.order < $1.order }) {
                check.category = daily
                check.order = order
                check.updatedAt = timeSource.now
                order += 1
            }
            daily.updatedAt = timeSource.now
        }
        context.delete(category)
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
    func deleteAllLogs() throws -> [String] {
        let photos = Array(try photoFileNames())
        // One by one: a batch delete fails on the LogEntry ↔ Check relationship.
        for entry in try context.fetch(FetchDescriptor<LogEntry>()) {
            entry.check?.updatedAt = timeSource.now
            context.delete(entry)
        }
        try context.save()
        return photos
    }

    @discardableResult
    func deleteEverything() throws -> [String] {
        let photos = Array(try photoFileNames())
        // Their logs go with them (cascade).
        for check in try allCheckModels() {
            context.delete(check)
        }
        for category in try allCategoryModels() {
            context.delete(category)
        }
        try context.save()
        return photos
    }

    // MARK: - Models

    /// In the whole list's order: category order, then the check's own.
    private func allCheckModels() throws -> [Check] {
        try context.fetch(FetchDescriptor<Check>(sortBy: [SortDescriptor(\.order), SortDescriptor(\.createdAt)]))
            .enumerated()
            .sorted { ($0.element.category?.order ?? 0, $0.offset) < ($1.element.category?.order ?? 0, $1.offset) }
            .map(\.element)
    }

    private func allCategoryModels() throws -> [CheckCategory] {
        try context.fetch(FetchDescriptor<CheckCategory>(sortBy: [SortDescriptor(\.order), SortDescriptor(\.createdAt)]))
    }

    private func categoryModel(_ id: UUID) throws -> CheckCategory? {
        var descriptor = FetchDescriptor<CheckCategory>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Daily, inserted (unsaved) when it isn't there yet.
    private func dailyModel() throws -> CheckCategory {
        try CategoryDefaults.dailyModel(in: context, now: timeSource.now)
    }

    /// The category with this id (Daily inserted, unsaved, if it's Daily and missing), else `categoryNotFound`.
    private func existingCategoryModel(_ id: UUID) throws -> CheckCategory {
        if id == CategoryDefaults.dailyID { return try dailyModel() }
        guard let model = try categoryModel(id) else { throw StoreError.categoryNotFound }
        return model
    }

    /// The cleaned name, unless it's empty or another category (ignoring case) has it.
    private func validatedName(_ raw: String, excluding id: UUID?) throws -> String {
        guard let name = CheckName.cleaned(raw) else { throw StoreError.invalidCategoryName }
        let key = CheckName.key(name)
        let taken = try allCategoryModels().contains { $0.id != id && CheckName.key($0.name) == key }
        guard !taken else { throw StoreError.invalidCategoryName }
        return name
    }

    private func updateCategory(_ id: UUID, _ change: (CheckCategory) throws -> Void) throws {
        let model = try existingCategoryModel(id)
        try change(model)
        model.updatedAt = timeSource.now
        try context.save()
    }

    private static func clampedMinutes(_ minutes: Int?) -> Int? {
        minutes.map { min(max($0, 0), 24 * 60 - 1) }
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
            categoryID: model.category?.id ?? CategoryDefaults.dailyID,
            nudgesOnLeavingHome: model.nudgesOnLeavingHome
        )
    }

    private static func record(_ model: CheckCategory) -> CategoryRecord {
        CategoryRecord(
            id: model.id,
            name: model.name,
            icon: CategoryIcon(rawValue: model.iconRaw) ?? .sun,
            colour: CategoryColour(key: model.colourRaw) ?? .violet,
            rule: model.isDefault ? .daily : model.rule,
            reminderMinutes: model.reminderMinutes,
            order: model.order,
            isDefault: model.isDefault
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
