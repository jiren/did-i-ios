import Foundation
import SwiftData
import Testing
@testable import Did_I

@MainActor
struct CategoryStoreTests {
    private let clock = FixedTimeSource(TestTime.date(2026, 10, 30, 8))
    private let store: SwiftDataStore

    init() throws {
        store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
    }

    private var binNight: CategoryDraft {
        CategoryDraft(name: "Bin night", icon: .bin, colour: .mint, rule: .weekly(weekday: 6), reminderMinutes: 20 * 60)
    }

    @Test func dailyAlwaysExists() throws {
        let categories = try store.categories()
        #expect(categories.map(\.name) == ["Daily"])
        #expect(categories[0].id == CategoryDefaults.dailyID)
        #expect(categories[0].isDefault)
        #expect(categories[0].rule == .daily)
        #expect(try store.categories().count == 1)
    }

    @Test func checksGoToDailyUnlessToldOtherwise() throws {
        let door = try store.addChecks([CheckDraft(name: "Front door locked")])[0]
        #expect(door.categoryID == CategoryDefaults.dailyID)
        let bins = try store.addCategory(binNight, tasks: [])
        let added = try store.addChecks([CheckDraft(name: "Bins out")], to: bins.id)
        #expect(added.map(\.categoryID) == [bins.id])
        #expect(throws: StoreError.categoryNotFound) { try store.addChecks([CheckDraft(name: "X")], to: UUID()) }
    }

    @Test func addsACategoryWithItsTasks() throws {
        _ = try store.addChecks([CheckDraft(name: "Bins out")])
        let bins = try store.addCategory(binNight, tasks: [CheckDraft(name: "Recycling out"), CheckDraft(name: "bins out")])
        #expect(bins.name == "Bin night")
        #expect(bins.icon == .bin)
        #expect(bins.colour == .mint)
        #expect(bins.rule == .weekly(weekday: 6))
        #expect(bins.reminderMinutes == 20 * 60)
        #expect(bins.order == 1)
        // "bins out" is already in Daily, so only Recycling out joins.
        #expect(try store.checks().filter { $0.categoryID == bins.id }.map(\.name) == ["Recycling out"])
        #expect(try store.category(id: bins.id) == bins)
    }

    @Test func refusesEmptyAndUsedNames() throws {
        _ = try store.addCategory(binNight, tasks: [])
        #expect(throws: StoreError.invalidCategoryName) { try store.addCategory(CategoryDraft(name: "  "), tasks: []) }
        #expect(throws: StoreError.invalidCategoryName) { try store.addCategory(CategoryDraft(name: "bin NIGHT"), tasks: []) }
        #expect(throws: StoreError.invalidCategoryName) { try store.addCategory(CategoryDraft(name: "daily"), tasks: []) }
    }

    @Test func editsACategory() throws {
        let bins = try store.addCategory(binNight, tasks: [])
        let anchor = CalendarDay(year: 2026, month: 11, day: 6)
        let edited = CategoryDraft(name: "Bins", icon: .home, colour: .sky, rule: .everyTwoWeeks(weekday: 6, anchor: anchor), reminderMinutes: nil)
        try store.updateCategory(bins.id, to: edited)
        let record = try #require(try store.category(id: bins.id))
        #expect(record.name == "Bins")
        #expect(record.icon == .home)
        #expect(record.colour == .sky)
        #expect(record.rule == .everyTwoWeeks(weekday: 6, anchor: anchor))
        #expect(record.reminderMinutes == nil)
        // Keeping its own name is fine.
        try store.updateCategory(bins.id, to: edited)
    }

    @Test func storesACustomColourAndALibraryIcon() throws {
        let category = try store.addCategory(
            CategoryDraft(name: "Pets", icon: CategoryIcon(symbol: "pawprint.fill"), colour: .custom(hex: "#123456")), tasks: []
        )
        let saved = try #require(try store.category(id: category.id))
        #expect(saved.colour == .custom(hex: "#123456"))
        #expect(saved.icon.symbolName == "pawprint.fill")
    }

    @Test func storesEveryRepeatRule() throws {
        let rules: [RepeatRule] = [
            .daily, .weekly(weekday: 2), .everyTwoWeeks(weekday: 6, anchor: CalendarDay(year: 2026, month: 10, day: 30)),
            .monthly(day: 31), .yearly(month: 2, day: 29), .once(CalendarDay(year: 2026, month: 11, day: 2)),
        ]
        for (index, rule) in rules.enumerated() {
            let category = try store.addCategory(CategoryDraft(name: "Rule \(index)", rule: rule), tasks: [])
            #expect(try store.category(id: category.id)?.rule == rule)
        }
    }

    @Test func dailyCanBeRenamedButNotRescheduledOrDeleted() throws {
        try store.updateCategory(CategoryDefaults.dailyID, to: CategoryDraft(name: "Every day", icon: .heart, colour: .pink))
        #expect(try store.category(id: CategoryDefaults.dailyID)?.name == "Every day")
        #expect(throws: StoreError.defaultCategoryIsFixed) {
            try store.updateCategory(CategoryDefaults.dailyID, to: CategoryDraft(name: "Every day", rule: .weekly(weekday: 2)))
        }
        #expect(throws: StoreError.defaultCategoryIsFixed) { try store.deleteCategory(CategoryDefaults.dailyID, .deleteTasks) }
    }

    @Test func reordersCategoriesAndTheWholeList() throws {
        _ = try store.addChecks([CheckDraft(name: "Front door locked")])
        let bins = try store.addCategory(binNight, tasks: [CheckDraft(name: "Bins out")])
        let travel = try store.addCategory(CategoryDraft(name: "Travel"), tasks: [CheckDraft(name: "Passport packed")])
        try store.reorderCategories([travel.id, bins.id])
        #expect(try store.categories().map(\.name) == ["Travel", "Bin night", "Daily"])
        #expect(try store.checks().map(\.name) == ["Passport packed", "Bins out", "Front door locked"])
    }

    @Test func deletingWithTasksRemovesTheirLogsAndPhotos() throws {
        let bins = try store.addCategory(binNight, tasks: [CheckDraft(name: "Bins out"), CheckDraft(name: "Recycling out")])
        let door = try store.addChecks([CheckDraft(name: "Front door locked")])[0]
        let tasks = try store.checks().filter { $0.categoryID == bins.id }
        _ = try store.log(tasks[0].id, source: .app, at: clock.now, photoFileName: "bins.heic")
        _ = try store.log(tasks[1].id, source: .app, at: clock.now, photoFileName: nil)
        _ = try store.log(door.id, source: .app, at: clock.now, photoFileName: "door.heic")

        #expect(try store.deleteCategory(bins.id, .deleteTasks) == ["bins.heic"])
        #expect(try store.categories().map(\.name) == ["Daily"])
        #expect(try store.checks().map(\.name) == ["Front door locked"])
        #expect(try store.logs(for: nil, limit: nil).map(\.checkID) == [door.id])
        #expect(try store.photoFileNames() == ["door.heic"])
    }

    @Test func deletingCanMoveTasksToDailyWithTheirLogs() throws {
        _ = try store.addChecks([CheckDraft(name: "Front door locked")])
        let bins = try store.addCategory(binNight, tasks: [CheckDraft(name: "Bins out"), CheckDraft(name: "Recycling out")])
        let binsOut = try #require(try store.checks().first { $0.name == "Bins out" })
        _ = try store.log(binsOut.id, source: .app, at: clock.now, photoFileName: "bins.heic")

        #expect(try store.deleteCategory(bins.id, .moveTasksToDaily).isEmpty)
        let checks = try store.checks()
        #expect(checks.map(\.name) == ["Front door locked", "Bins out", "Recycling out"])
        #expect(checks.allSatisfy { $0.categoryID == CategoryDefaults.dailyID })
        #expect(try store.logCount(for: binsOut.id) == 1)
        #expect(try store.photoFileNames() == ["bins.heic"])
    }

    @Test func movesATaskToTheEndOfAnotherCategory() throws {
        let bins = try store.addCategory(binNight, tasks: [CheckDraft(name: "Bins out")])
        let door = try store.addChecks([CheckDraft(name: "Front door locked"), CheckDraft(name: "Pill taken")])[0]
        try store.moveCheck(door.id, to: bins.id)
        #expect(try store.checks().map(\.name) == ["Pill taken", "Bins out", "Front door locked"])
        #expect(try store.check(id: door.id)?.categoryID == bins.id)
        #expect(throws: StoreError.categoryNotFound) { try store.moveCheck(door.id, to: UUID()) }
    }

    @Test func setsAndClampsTheReminder() throws {
        try store.setReminder(minutes: 21 * 60, forCategory: CategoryDefaults.dailyID)
        #expect(try store.category(id: CategoryDefaults.dailyID)?.reminderMinutes == 21 * 60)
        try store.setReminder(minutes: 99_999, forCategory: CategoryDefaults.dailyID)
        #expect(try store.category(id: CategoryDefaults.dailyID)?.reminderMinutes == 24 * 60 - 1)
    }

    @Test func deletingEverythingLeavesAnEmptyDaily() throws {
        _ = try store.addCategory(binNight, tasks: [CheckDraft(name: "Bins out")])
        try store.updateCategory(CategoryDefaults.dailyID, to: CategoryDraft(name: "Every day"))
        try store.deleteEverything()
        #expect(try store.checks().isEmpty)
        #expect(try store.categories().map(\.name) == ["Daily"])
    }
}

/// A store from phases 0–12 opens as V2: its checks go into Daily, which takes the earliest reminder.
@MainActor
struct MigrationTests {
    @Test func aVersion1StoreMigratesToCategories() throws {
        let url = URL.temporaryDirectory.appending(path: "DidI-V1-\(UUID().uuidString).store")
        defer {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(at: URL(filePath: url.path() + suffix))
            }
        }
        let now = TestTime.date(2026, 10, 29, 8)
        let doorID = UUID()
        try writeVersion1Store(at: url, now: now, doorID: doorID)

        let container = try ModelContainer.app(url: url)
        let store = SwiftDataStore(container: container)
        let categories = try store.categories()
        #expect(categories.map(\.name) == ["Daily"])
        #expect(categories.first?.reminderMinutes == 8 * 60 + 30)

        let checks = try store.checks()
        #expect(checks.map(\.name) == ["Front door locked", "Pill taken", "Stove off"])
        let models = try ModelContext(container).fetch(FetchDescriptor<Check>())
        #expect(models.allSatisfy { $0.category?.id == CategoryDefaults.dailyID })

        #expect(try store.logCount(for: doorID) == 2)
        #expect(try store.photoFileNames() == ["door.heic"])
        #expect(try store.latestLogs()[doorID]?.source == .lockScreenWidget)
    }

    private func writeVersion1Store(at url: URL, now: Date, doorID: UUID) throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        let context = ModelContext(container)
        let door = SchemaV1.Check(id: doorID, name: "Front door locked", kind: .door, order: 0, now: now)
        door.reminderMinutes = 21 * 60
        let pill = SchemaV1.Check(name: "Pill taken", kind: .pill, order: 1, now: now)
        pill.reminderMinutes = 8 * 60 + 30
        let stove = SchemaV1.Check(name: "Stove off", kind: .stove, order: 2, now: now)
        [door, pill, stove].forEach(context.insert)
        context.insert(SchemaV1.LogEntry(date: now, source: .app, photoFileName: "door.heic", check: door))
        context.insert(SchemaV1.LogEntry(date: now.addingTimeInterval(60), source: .lockScreenWidget, photoFileName: nil, check: door))
        try context.save()
    }
}
