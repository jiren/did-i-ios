import Foundation
import Testing
@testable import Did_I

/// Thursday, Oct 29, 2026 at 10:42 AM.
@MainActor
struct CategoryEditorViewModelTests {
    private let clock = FixedTimeSource(TestTime.date(2026, 10, 29, 10, 42))
    private let store: SwiftDataStore
    private let changes = ChangeSpy()

    init() throws {
        store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
    }

    private func names(_ viewModel: CategoryEditorViewModel) -> [String] { viewModel.tasks.map(\.name) }

    private func editor(_ id: UUID? = nil) -> CategoryEditorViewModel {
        let viewModel = CategoryEditorViewModel(
            editing: id, store: store, editor: CheckEditor(store: store, changes: changes, photos: nil), changes: changes,
            days: FixedDays(), timeSource: clock, locale: Locale(identifier: "en_US")
        )
        viewModel.load()
        return viewModel
    }

    @Test func aNewCategoryStartsBlank() {
        let viewModel = editor()
        #expect(viewModel.isNew)
        #expect(viewModel.title == "New category")
        #expect(viewModel.commitTitle == "Create category")
        #expect(!viewModel.canSave)
        #expect(viewModel.previewName == "New category")
        #expect(viewModel.previewDetail == "0 tasks · No reminder")
        // Daily is Violet, so the first free colour is Sun; today's weekday and day are the defaults.
        #expect(viewModel.colour == .sun)
        #expect(viewModel.weekday == 5)
        #expect(viewModel.monthDay == 29)
    }

    @Test func thePreviewFollowsTheForm() {
        let viewModel = editor()
        viewModel.name = "Weekend trip"
        viewModel.repeatKind = .once
        viewModel.date = TestTime.date(2026, 11, 6, 12)
        viewModel.taskText = "Passport packed"
        viewModel.addTask()
        viewModel.taskText = "Charger packed"
        viewModel.addTask()
        viewModel.taskText = "passport PACKED"
        viewModel.addTask()
        viewModel.remindsMe = true
        #expect(viewModel.previewName == "Weekend trip")
        #expect(viewModel.repeatSummary == "Once · Fri, Nov 6")
        #expect(names(viewModel) == ["Passport packed", "Charger packed"])
        #expect(viewModel.previewDetail.plainSpaces == "2 tasks · Reminder at 8:00 PM")
        viewModel.removeTask(viewModel.tasks[1].id)
        #expect(viewModel.taskCountText == "1 task")
    }

    @Test func createsAWeeklyCategoryWithItsTasks() throws {
        let viewModel = editor()
        viewModel.name = " Bin night "
        viewModel.icon = .bin
        viewModel.colour = .mint
        viewModel.repeatKind = .weekly
        viewModel.weekday = 6
        viewModel.remindsMe = true
        viewModel.reminderTime = TestTime.date(2026, 10, 29, 19, 30)
        viewModel.taskText = "Bins out"
        viewModel.addTask()
        #expect(viewModel.save())
        let category = try #require(try store.categories().last)
        #expect(category.name == "Bin night")
        #expect(category.icon == .bin)
        #expect(category.colour == .mint)
        #expect(category.rule == .weekly(weekday: 6))
        #expect(category.reminderMinutes == 19 * 60 + 30)
        #expect(try store.checks().map(\.categoryID) == [category.id])
        #expect(changes.count == 1)
    }

    @Test func everyOtherWeekStartsOnTheNextMatchingDay() throws {
        let viewModel = editor()
        viewModel.name = "Recycling"
        viewModel.repeatKind = .everyTwoWeeks
        viewModel.weekday = 6
        #expect(viewModel.rule == .everyTwoWeeks(weekday: 6, anchor: CalendarDay(year: 2026, month: 10, day: 30)))
    }

    @Test func aUsedNameIsRefused() {
        let viewModel = editor()
        viewModel.name = "daily"
        #expect(!viewModel.save())
        #expect(viewModel.errorMessage == "There’s already a category called “daily”.")
        #expect(changes.count == 0)
    }

    @Test func editingKeepsWhatItDoesntChange() throws {
        let anchor = CalendarDay(year: 2026, month: 10, day: 16)
        let bins = try store.addCategory(
            CategoryDraft(name: "Recycling", icon: .bin, colour: .mint, rule: .everyTwoWeeks(weekday: 6, anchor: anchor), reminderMinutes: 20 * 60),
            tasks: [CheckDraft(name: "Recycling out")]
        )
        let viewModel = editor(bins.id)
        #expect(viewModel.title == "Edit category")
        #expect(viewModel.commitTitle == "Save")
        #expect(names(viewModel) == ["Recycling out"])
        #expect(viewModel.remindsMe)
        #expect(viewModel.rule == .everyTwoWeeks(weekday: 6, anchor: anchor))
        viewModel.name = "Recycling night"
        viewModel.taskText = "Glass out"
        viewModel.addTask()
        #expect(viewModel.save())
        let saved = try #require(try store.category(id: bins.id))
        #expect(saved.name == "Recycling night")
        #expect(saved.rule == .everyTwoWeeks(weekday: 6, anchor: anchor))
        #expect(try store.checks().filter { $0.categoryID == bins.id }.map(\.name) == ["Recycling out", "Glass out"])
    }

    @Test func editingAYearlyCategoryShowsItsNextDate() throws {
        let birthday = try store.addCategory(CategoryDraft(name: "Birthday", rule: .yearly(month: 2, day: 29)), tasks: [])
        let viewModel = editor(birthday.id)
        #expect(CalendarDay(viewModel.date, calendar: TestTime.calendar()) == CalendarDay(year: 2028, month: 2, day: 29))
        #expect(viewModel.rule == .yearly(month: 2, day: 29))
    }

    // MARK: - Templates and task editing (Phase 20)

    @Test func aTemplateFillsTheForm() {
        let viewModel = editor()
        let binNight = CategoryTemplates.all.first { $0.id == "binNight" }!
        viewModel.apply(binNight)
        #expect(viewModel.name == "Bin night")
        #expect(viewModel.icon == .bin)
        #expect(viewModel.colour == .mint)
        #expect(viewModel.rule == .weekly(weekday: 5))
        #expect(viewModel.remindsMe)
        #expect(viewModel.previewDetail.plainSpaces == "2 tasks · Reminder at 8:00 PM")
        #expect(names(viewModel) == ["Bins out", "Recycling out"])
    }

    @Test func aUsedTemplateNameGetsANumber() throws {
        _ = try store.addCategory(CategoryDraft(name: "Gym"), tasks: [])
        _ = try store.addCategory(CategoryDraft(name: "gym 2"), tasks: [])
        let viewModel = editor()
        viewModel.apply(CategoryTemplates.all.first { $0.id == "gym" }!)
        #expect(viewModel.name == "Gym 3")
        #expect(viewModel.save())
    }

    @Test func tasksAreRenamedReorderedAndRemovedBeforeSaving() throws {
        let viewModel = editor()
        viewModel.apply(CategoryTemplates.all.first { $0.id == "gym" }!)
        viewModel.tasks[1].name = "Towel"
        viewModel.removeTask(viewModel.tasks[2].id)
        viewModel.moveTask(viewModel.tasks[1].id, to: viewModel.tasks[0].id)
        viewModel.tasks.append(.new("   "))
        #expect(viewModel.taskCountText == "2 tasks")
        #expect(viewModel.save())
        let gym = try #require(try store.categories().first { $0.name == "Gym" })
        #expect(try store.checks().filter { $0.categoryID == gym.id }.map(\.name) == ["Towel", "Water bottle"])
        #expect(gym.icon == CategoryIcon(symbol: "figure.run"))
    }

    @Test func aTaskInAnotherCategoryMovesHere() throws {
        let stove = try store.addChecks([CheckDraft(name: "Stove off")])[0]
        _ = try store.log(stove.id, source: .app, at: clock.now, photoFileName: nil)
        let viewModel = editor()
        viewModel.apply(CategoryTemplates.all.first { $0.id == "bedtime" }!)
        let draft = try #require(viewModel.tasks.first { $0.name == "Stove off" })
        #expect(viewModel.note(for: draft) == "In Daily · moves here")
        #expect(viewModel.save())
        let bedtime = try #require(try store.categories().first { $0.name == "Bedtime" })
        #expect(try store.check(id: stove.id)?.categoryID == bedtime.id)
        #expect(try store.logCount(for: stove.id) == 1)
        #expect(try store.checks().filter { $0.name == "Stove off" }.count == 1)
    }

    @Test func editingRenamesAndRemovesSavedTasksAfterAsking() throws {
        let bins = try store.addCategory(
            CategoryDraft(name: "Bin night", rule: .weekly(weekday: 6)),
            tasks: [CheckDraft(name: "Bins out"), CheckDraft(name: "Recycling out")]
        )
        let recycling = try #require(try store.checks().first { $0.name == "Recycling out" })
        _ = try store.log(recycling.id, source: .app, at: clock.now, photoFileName: nil)
        let viewModel = editor(bins.id)
        viewModel.tasks[0].name = "Bins out by 8"
        viewModel.removeTask(viewModel.tasks[1].id)

        #expect(!viewModel.save())
        #expect(viewModel.removalQuestion == "Remove Recycling out and its 1 logs?")
        viewModel.cancelRemoval()
        #expect(names(viewModel) == ["Bins out by 8", "Recycling out"])

        viewModel.removeTask(viewModel.tasks[1].id)
        #expect(!viewModel.save())
        #expect(viewModel.save())
        #expect(try store.checks().filter { $0.categoryID == bins.id }.map(\.name) == ["Bins out by 8"])
        #expect(try store.check(id: recycling.id) == nil)
    }

    @Test func aCustomColourAndALibraryIconSave() throws {
        let viewModel = editor()
        viewModel.name = "Fish"
        viewModel.setCustomColour(red: 0.1, green: 0.2, blue: 0.8)
        viewModel.icon = CategoryIcon(symbol: "fish.fill")
        #expect(viewModel.save())
        let fish = try #require(try store.categories().first { $0.name == "Fish" })
        #expect(fish.colour == .custom(hex: "#1A33CC"))
        #expect(fish.icon.symbolName == "fish.fill")
        #expect(!fish.icon.isFeatured)
    }

    @Test func dailyKeepsItsSchedule() throws {
        let viewModel = editor(CategoryDefaults.dailyID)
        #expect(viewModel.isDaily)
        viewModel.name = "Every day"
        viewModel.repeatKind = .weekly
        #expect(viewModel.save())
        let daily = try #require(try store.category(id: CategoryDefaults.dailyID))
        #expect(daily.name == "Every day")
        #expect(daily.rule == .daily)
    }
}

@MainActor
struct CategoriesViewModelTests {
    private let clock = FixedTimeSource(TestTime.date(2026, 10, 29, 10, 42))
    private let store: SwiftDataStore
    private let changes = ChangeSpy()
    private let viewModel: CategoriesViewModel

    init() throws {
        store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
        viewModel = CategoriesViewModel(
            store: store, editor: CategoryEditor(store: store, changes: changes, photos: nil), days: FixedDays(),
            timeSource: clock, locale: Locale(identifier: "en_US")
        )
    }

    @Test func pastOneOffsAreListedApart() throws {
        _ = try store.addCategory(CategoryDraft(name: "Bin night", rule: .weekly(weekday: 6)), tasks: [CheckDraft(name: "Bins out")])
        _ = try store.addCategory(CategoryDraft(name: "Old trip", rule: .once(CalendarDay(year: 2026, month: 10, day: 1))), tasks: [])
        viewModel.load()
        #expect(viewModel.current.map(\.category.name) == ["Daily", "Bin night"])
        #expect(viewModel.current[1].detail == "Every Friday · 1 task")
        #expect(viewModel.past.map(\.category.name) == ["Old trip"])
    }

    @Test func dragsToReorder() throws {
        _ = try store.addCategory(CategoryDraft(name: "Bin night", rule: .weekly(weekday: 6)), tasks: [])
        _ = try store.addCategory(CategoryDraft(name: "Travel", rule: .monthly(day: 1)), tasks: [])
        viewModel.load()
        viewModel.move(from: IndexSet(integer: 2), to: 0)
        #expect(viewModel.current.map(\.category.name) == ["Travel", "Daily", "Bin night"])
        viewModel.move(from: IndexSet(integer: 0), to: 3)
        #expect(viewModel.current.map(\.category.name) == ["Daily", "Bin night", "Travel"])
        #expect(changes.count == 2)
    }

    @Test func deletingAsksAndDailyCant() throws {
        let bins = try store.addCategory(CategoryDraft(name: "Bin night"), tasks: [CheckDraft(name: "Bins out"), CheckDraft(name: "Recycling out")])
        viewModel.load()
        viewModel.askToDelete(CategoryDefaults.dailyID)
        #expect(viewModel.deletion == nil)
        viewModel.askToDelete(bins.id)
        #expect(viewModel.deletion?.taskCount == 2)
        viewModel.delete(bins.id, .moveTasksToDaily)
        #expect(viewModel.current.map(\.category.name) == ["Daily"])
        #expect(try store.checks().count == 2)
    }
}
