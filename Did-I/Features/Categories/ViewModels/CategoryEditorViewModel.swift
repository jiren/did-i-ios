import Foundation
import Observation

/// New category and Edit category (`NewCategory.dc.html`): name, icon, colour, repeat, tasks and the reminder,
/// with a live preview.
@Observable
final class CategoryEditorViewModel {
    /// The reminder time when it's first turned on, as drawn.
    static let defaultReminderMinutes = 20 * 60

    var name = ""
    var icon: CategoryIcon = .suitcase
    var colour: TileSwatch = .sky
    var repeatKind: RepeatKind = .daily
    /// 1 (Sunday) to 7, for Weekly and Every 2 weeks.
    var weekday = 6
    /// 1 to 31, for Monthly.
    var monthDay = 1
    /// For Yearly and On a date.
    var date = Date()
    var remindsMe = false
    var reminderTime = Date()
    var taskText = ""
    /// Tasks to add on save.
    private(set) var newTasks: [String] = []
    /// An edited category's tasks, already saved.
    private(set) var existingTasks: [String] = []
    private(set) var errorMessage: String?

    /// The category being edited, or nil for a new one.
    let editedID: UUID?
    /// Daily keeps its schedule.
    private(set) var isDaily = false

    @ObservationIgnored private let store: any CheckStoring & CategoryStoring
    @ObservationIgnored private let changes: any ChangeNotifying
    @ObservationIgnored private let days: any DayBoundaryProviding
    @ObservationIgnored private let timeSource: any TimeSource
    @ObservationIgnored private let locale: Locale
    /// An every-two-weeks rule loaded for editing, kept when its weekday doesn't change.
    @ObservationIgnored private var loadedRule: RepeatRule?

    init(
        editing id: UUID? = nil,
        store: any CheckStoring & CategoryStoring,
        changes: any ChangeNotifying,
        days: any DayBoundaryProviding,
        timeSource: any TimeSource,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.editedID = id
        self.store = store
        self.changes = changes
        self.days = days
        self.timeSource = timeSource
        self.locale = locale
    }

    private var calendar: Calendar { days.dayBoundary.calendar }
    private var today: CalendarDay { days.dayBoundary.calendarDay(containing: timeSource.now) }

    /// Fills the form: an edited category's details, or a new one's defaults (today's weekday and day of the
    /// month, tomorrow's date, the first colour not used yet).
    func load() {
        weekday = today.weekday(in: calendar)
        monthDay = today.day
        date = today.adding(days: 1, calendar: calendar).noon(in: calendar)
        reminderTime = time(minutes: Self.defaultReminderMinutes)
        let categories = (try? store.categories()) ?? []
        guard let editedID, let category = categories.first(where: { $0.id == editedID }) else {
            let used = Set(categories.map(\.colour))
            colour = TileSwatch.allCases.first { !used.contains($0) } ?? .sky
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
        case .weekly(let day), .everyTwoWeeks(let day, _): weekday = day
        case .monthly(let day): monthDay = day
        case .yearly(let month, let day): date = Self.yearlyDate(month: month, day: day, from: today, calendar: calendar)
        case .once(let day): date = day.noon(in: calendar)
        }
        if let minutes = category.reminderMinutes {
            remindsMe = true
            reminderTime = time(minutes: minutes)
        }
        existingTasks = ((try? store.checks()) ?? []).filter { $0.categoryID == editedID }.map(\.name)
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
        case .weekly: return .weekly(weekday: weekday)
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

    /// "3 tasks" or "1 task".
    var taskCountText: String {
        let count = existingTasks.count + newTasks.count
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

    func addTask() {
        guard let task = CheckName.cleaned(taskText) else { return }
        taskText = ""
        let taken = (existingTasks + newTasks).contains { CheckName.key($0) == CheckName.key(task) }
        guard !taken else { return }
        newTasks.append(task)
    }

    func removeTask(_ task: String) {
        newTasks.removeAll { $0 == task }
    }

    // MARK: - Saving

    /// Creates or updates the category. Returns whether it saved; if not, `errorMessage` says why.
    @discardableResult
    func save() -> Bool {
        guard let cleaned = CheckName.cleaned(name) else {
            errorMessage = String(localized: "Give it a name.")
            return false
        }
        let draft = CategoryDraft(
            name: cleaned, icon: icon, colour: colour, rule: isDaily ? .daily : rule,
            reminderMinutes: remindsMe ? minutes(of: reminderTime) : nil
        )
        do {
            if let editedID {
                try store.updateCategory(editedID, to: draft)
                if !newTasks.isEmpty { try store.addChecks(newTasks.map { CheckDraft(name: $0) }, to: editedID) }
            } else {
                try store.addCategory(draft, tasks: newTasks.map { CheckDraft(name: $0) })
            }
            errorMessage = nil
            changes.didChange()
            return true
        } catch StoreError.invalidCategoryName {
            errorMessage = String(localized: "There’s already a category called “\(cleaned)”.")
        } catch {
            errorMessage = String(localized: "Couldn’t save the category.")
        }
        return false
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
