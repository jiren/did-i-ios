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

    private func editor(_ id: UUID? = nil) -> CategoryEditorViewModel {
        let viewModel = CategoryEditorViewModel(
            editing: id, store: store, changes: changes, days: FixedDays(), timeSource: clock, locale: Locale(identifier: "en_US")
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
        #expect(viewModel.newTasks == ["Passport packed", "Charger packed"])
        #expect(viewModel.previewDetail.plainSpaces == "2 tasks · Reminder at 8:00 PM")
        viewModel.removeTask("Charger packed")
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
        #expect(viewModel.existingTasks == ["Recycling out"])
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
