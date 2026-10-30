import Foundation
import Observation

/// A task on New or Edit category, as typed: a new name, or a task already in this category.
struct TaskDraft: Identifiable, Equatable {
    let id = UUID()
    var name: String
    /// The saved check it edits, if any.
    let checkID: UUID?
    /// Its name when loaded, to spot a rename.
    let savedName: String?

    static func new(_ name: String) -> TaskDraft {
        TaskDraft(name: name, checkID: nil, savedName: nil)
    }
}

/// New category and Edit category (`NewCategory.dc.html`, Phase 20): a template's or a category's details, its
/// tasks to add, rename, reorder or remove, a custom colour or library icon, and the reminder, with a live preview.
@Observable
final class CategoryEditorViewModel {
    /// The reminder time when it's first turned on, as drawn.
    static let defaultReminderMinutes = 20 * 60

    var name = ""
    var icon: CategoryIcon = .suitcase
    var colour: CategoryColour = .sky
    var repeatKind: RepeatKind = .daily
    /// 1 (Sunday) to 7, for Every 2 weeks.
    var weekday = 6
    /// The days for Weekly: one or more.
    var weekdays: Set<Int> = [6]
    /// 1 to 31, for Monthly.
    var monthDay = 1
    /// For Yearly and On a date.
    var date = Date()
    var remindsMe = false
    var reminderTime = Date()
    var taskText = ""
    /// In order; names are edited in place.
    var tasks: [TaskDraft] = []
    private(set) var errorMessage: String?
    /// Set when saving would remove saved tasks: "Remove 2 tasks and their 14 logs?". Save again to confirm.
    private(set) var removalQuestion: String?

    /// The category being edited, or nil for a new one.
    let editedID: UUID?
    /// Daily keeps its schedule.
    private(set) var isDaily = false

    @ObservationIgnored private let store: any CheckStoring & CategoryStoring & LogStoring
    @ObservationIgnored private let editor: CheckEditor
    @ObservationIgnored private let changes: any ChangeNotifying
    @ObservationIgnored private let days: any DayBoundaryProviding
    @ObservationIgnored private let timeSource: any TimeSource
    @ObservationIgnored private let locale: Locale
    /// An every-two-weeks rule loaded for editing, kept when its weekday doesn't change.
    @ObservationIgnored private var loadedRule: RepeatRule?
    /// Saved tasks of this category taken off the list, removed on save.
    @ObservationIgnored private var removedTasks: [TaskDraft] = []
    @ObservationIgnored private var categories: [CategoryRecord] = []
    @ObservationIgnored private var isLoaded = false

    init(
        editing id: UUID? = nil,
        store: any CheckStoring & CategoryStoring & LogStoring,
        editor: CheckEditor,
        changes: any ChangeNotifying,
        days: any DayBoundaryProviding,
        timeSource: any TimeSource,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.editedID = id
        self.store = store
        self.editor = editor
        self.changes = changes
        self.days = days
        self.timeSource = timeSource
        self.locale = locale
    }

    private var calendar: Calendar { days.dayBoundary.calendar }
    private var today: CalendarDay { days.dayBoundary.calendarDay(containing: timeSource.now) }

    /// Fills the form: an edited category's details and tasks, or a new one's defaults (today's weekday and day of
    /// the month, tomorrow's date, the first colour not used yet). Only once, so a template applied after it stays.
    func load() {
        guard !isLoaded else { return }
        isLoaded = true
        categories = (try? store.categories()) ?? []
        let checks = (try? store.checks()) ?? []
        weekday = today.weekday(in: calendar)
        weekdays = [weekday]
        monthDay = today.day
        date = today.adding(days: 1, calendar: calendar).noon(in: calendar)
        reminderTime = time(minutes: Self.defaultReminderMinutes)
        guard let editedID, let category = categories.first(where: { $0.id == editedID }) else {
            let used = Set(categories.map(\.colour))
            colour = CategoryColour.swatches.first { !used.contains($0) } ?? .sky
            return
        }
        name = category.name
        icon = category.icon
        colour = category.colour
        isDaily = category.isDefault
        loadedRule = category.rule
        repeatKind = category.rule.kind
        switch category.rule {
        case .daily: break
        case .weekly(let days):
            weekdays = days
            weekday = days.min() ?? weekday
        case .everyTwoWeeks(let day, _):
            weekday = day
            weekdays = [day]
        case .monthly(let day): monthDay = day
        case .yearly(let month, let day): date = Self.yearlyDate(month: month, day: day, from: today, calendar: calendar)
        case .once(let day): date = day.noon(in: calendar)
        }
        if let minutes = category.reminderMinutes {
            remindsMe = true
            reminderTime = time(minutes: minutes)
        }
        tasks = checks.filter { $0.categoryID == editedID }.map {
            TaskDraft(name: $0.name, checkID: $0.id, savedName: $0.name)
        }
    }

    /// Fills the form from a template; everything stays editable.
    func apply(_ template: CategoryTemplate) {
        name = uniqueName(template.name)
        icon = template.icon
        colour = template.colour
        let rule = template.rule(today: today, calendar: calendar)
        repeatKind = rule.kind
        switch rule {
        case .weekly(let days): weekdays = days
        case .everyTwoWeeks(let day, _): weekday = day
        case .monthly(let day): monthDay = day
        case .once(let day): date = day.noon(in: calendar)
        default: break
        }
        remindsMe = template.reminderMinutes != nil
        reminderTime = time(minutes: template.reminderMinutes ?? Self.defaultReminderMinutes)
        tasks = []
        template.tasks.forEach(append)
    }

    /// `name`, or "name 2", "name 3"… when a category already has it (ignoring case).
    func uniqueName(_ name: String) -> String {
        let taken = Set(categories.filter { $0.id != editedID }.map { CheckName.key($0.name) })
        guard taken.contains(CheckName.key(name)) else { return name }
        var number = 2
        while taken.contains(CheckName.key("\(name) \(number)")) { number += 1 }
        return "\(name) \(number)"
    }

    var isNew: Bool { editedID == nil }

    var title: String { isNew ? String(localized: "New category") : String(localized: "Edit category") }

    var commitTitle: String { isNew ? String(localized: "Create category") : String(localized: "Save") }

    /// A name is all it needs.
    var canSave: Bool { CheckName.cleaned(name) != nil }

    var rule: RepeatRule {
        let day = CalendarDay(date, calendar: calendar)
        switch repeatKind {
        case .daily: return .daily
        case .weekly: return weekdays.isEmpty ? .weekly(weekday: weekday) : .weekly(weekdays: weekdays)
        case .everyTwoWeeks:
            if case .everyTwoWeeks(let loadedDay, _) = loadedRule, loadedDay == weekday, let loadedRule { return loadedRule }
            return .everyTwoWeeks(weekday: weekday, startingOnOrAfter: today, calendar: calendar)
        case .monthly: return .monthly(day: min(max(monthDay, 1), 31))
        case .yearly: return .yearly(month: day.month, day: day.day)
        case .once: return .once(day)
        }
    }

    // MARK: - Preview

    var previewName: String { CheckName.cleaned(name) ?? String(localized: "New category") }

    var repeatSummary: String { rule.label(calendar: calendar, locale: locale) }

    /// Tasks with a name.
    private var namedTasks: [TaskDraft] { tasks.filter { CheckName.cleaned($0.name) != nil } }

    /// "3 tasks" or "1 task".
    var taskCountText: String {
        let count = namedTasks.count
        return count == 1 ? String(localized: "1 task") : String(localized: "\(count) tasks")
    }

    /// "3 tasks · Reminder at 8:00 PM" or "1 task · No reminder".
    var previewDetail: String {
        let tasks = taskCountText
        guard remindsMe else { return String(localized: "\(tasks) · No reminder") }
        let time = reminderTime.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar, timeZone: calendar.timeZone))
        return String(localized: "\(tasks) · Reminder at \(time)")
    }

    /// "Date each year" or "Date".
    var dateLabel: String { repeatKind == .yearly ? String(localized: "Date each year") : String(localized: "Date") }

    // MARK: - Tasks

    var canAddTask: Bool { CheckName.cleaned(taskText) != nil }

    /// Adds the typed task, unless the list already has it.
    func addTask() {
        guard let task = CheckName.cleaned(taskText) else { return }
        taskText = ""
        append(task)
    }

    private func append(_ raw: String) {
        guard let name = CheckName.cleaned(raw) else { return }
        guard !tasks.contains(where: { CheckName.key($0.name) == CheckName.key(name) }) else { return }
        if let removed = removedTasks.firstIndex(where: { CheckName.key($0.name) == CheckName.key(name) }) {
            tasks.append(removedTasks.remove(at: removed))
        } else {
            tasks.append(.new(name))
        }
    }

    /// Takes a task off the list; a saved task of this category is removed on save, after asking.
    func removeTask(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        let task = tasks.remove(at: index)
        if task.checkID != nil { removedTasks.append(task) }
        removalQuestion = nil
    }

    /// A dragged task takes `target`'s place.
    func moveTask(_ id: UUID, to target: UUID) {
        guard id != target, let from = tasks.firstIndex(where: { $0.id == id }),
              let to = tasks.firstIndex(where: { $0.id == target }) else { return }
        let task = tasks.remove(at: from)
        tasks.insert(task, at: to)
    }

    // MARK: - Colour

    /// A colour from the colour picker (0–1 components).
    func setCustomColour(red: Double, green: Double, blue: Double) {
        colour = .custom(red: red, green: green, blue: blue)
    }

    // MARK: - Saving

    /// Creates or updates the category and its tasks. Returns whether it saved; if not, `errorMessage` says why, or
    /// `removalQuestion` asks before removing saved tasks (save again to confirm).
    @discardableResult
    func save() -> Bool {
        guard let cleaned = CheckName.cleaned(name) else {
            errorMessage = String(localized: "Give it a name.")
            return false
        }
        if removalQuestion == nil, let question = removalQuestionText() {
            removalQuestion = question
            return false
        }
        let draft = CategoryDraft(
            name: cleaned, icon: icon, colour: colour, rule: isDaily ? .daily : rule,
            reminderMinutes: remindsMe ? minutes(of: reminderTime) : nil
        )
        do {
            let categoryID: UUID
            if let editedID {
                try store.updateCategory(editedID, to: draft)
                categoryID = editedID
            } else {
                categoryID = try store.addCategory(draft, tasks: []).id
            }
            try saveTasks(in: categoryID)
            errorMessage = nil
            removalQuestion = nil
            changes.didChange()
            return true
        } catch StoreError.invalidCategoryName {
            errorMessage = String(localized: "There’s already a category called “\(cleaned)”.")
        } catch {
            errorMessage = String(localized: "Couldn’t save the category.")
        }
        removalQuestion = nil
        return false
    }

    /// Keeps the removed tasks after all: back on the list.
    func cancelRemoval() {
        tasks += removedTasks
        removedTasks = []
        removalQuestion = nil
    }

    /// Removes, renames and adds tasks, then puts them in the list's order.
    private func saveTasks(in categoryID: UUID) throws {
        for task in removedTasks {
            if let checkID = task.checkID { try editor.remove(checkID) }
        }
        removedTasks = []
        for task in namedTasks {
            guard let checkID = task.checkID, let cleaned = CheckName.cleaned(task.name) else { continue }
            if cleaned != task.savedName { try store.rename(checkID, to: cleaned) }
        }
        try store.addChecks(namedTasks.filter { $0.checkID == nil }.map { CheckDraft(name: $0.name) }, to: categoryID)
        let saved = try store.checks().filter { $0.categoryID == categoryID }
        let order = namedTasks.compactMap { task in
            task.checkID ?? saved.first { CheckName.key($0.name) == CheckName.key(task.name) }?.id
        }
        try store.reorder(order)
    }

    /// "Remove Towel packed and its 3 logs?", or nil when no saved task is being removed.
    private func removalQuestionText() -> String? {
        let removed = removedTasks.compactMap(\.checkID)
        guard !removed.isEmpty else { return nil }
        let logs = removed.reduce(0) { $0 + ((try? store.logCount(for: $1)) ?? 0) }
        if removed.count == 1, let name = removedTasks.first?.name {
            return logs == 0
                ? String(localized: "Remove \(name)?")
                : String(localized: "Remove \(name) and its \(logs) logs?")
        }
        return logs == 0
            ? String(localized: "Remove \(removed.count) tasks?")
            : String(localized: "Remove \(removed.count) tasks and their \(logs) logs?")
    }

    private func time(minutes: Int) -> Date {
        calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: timeSource.now) ?? timeSource.now
    }

    private func minutes(of date: Date) -> Int {
        calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    /// The next `month`/`day` on or after `today` (Feb 29 in a leap year).
    private static func yearlyDate(month: Int, day: Int, from today: CalendarDay, calendar: Calendar) -> Date {
        for year in today.year...(today.year + 8) {
            let candidate = CalendarDay(year: year, month: month, day: day)
            let date = candidate.noon(in: calendar)
            if CalendarDay(date, calendar: calendar) == candidate, candidate >= today { return date }
        }
        return today.noon(in: calendar)
    }
}
