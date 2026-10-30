import Foundation
import Testing
@testable import Did_I

private func category(reminder: Int?, rule: RepeatRule = .daily) -> CategoryRecord {
    CategoryRecord(id: UUID(), name: "Daily", icon: .sun, colour: .violet, rule: rule, reminderMinutes: reminder, order: 0, isDefault: false)
}

private func check(_ name: String, in category: CategoryRecord? = nil, nudge: Bool = false) -> CheckRecord {
    CheckRecord(id: UUID(), name: name, kind: .other, order: 0, categoryID: category?.id ?? CategoryDefaults.dailyID, nudgesOnLeavingHome: nudge)
}

private func log(_ check: CheckRecord, at date: Date) -> LogRecord {
    LogRecord(id: UUID(), checkID: check.id, date: date, source: .app, photoFileName: nil)
}

struct ReminderPlannerTests {
    private let boundary = DayBoundary(calendar: TestTime.calendar())
    private let now = TestTime.date(2026, 10, 29, 10)

    @Test func oneReminderPerCategoryTodayAndTomorrow() {
        let daily = category(reminder: 21 * 60)
        let tasks = [check("Front door locked", in: daily), check("Pill taken", in: daily)]
        let planned = ReminderPlanner.plan(checks: tasks, categories: [daily], latestLogs: [:], now: now, boundary: boundary)
        #expect(planned.map(\.fireDate) == [TestTime.date(2026, 10, 29, 21), TestTime.date(2026, 10, 30, 21)])
        #expect(planned.first?.title == "Daily")
        #expect(planned.first?.body == "2 left: Front door locked, Pill taken")
        #expect(planned.first?.checkID == nil)
        #expect(planned.first?.categoryID == daily.id)
    }

    @Test func oneTaskLeftCanBeLoggedFromTheReminder() {
        let daily = category(reminder: 21 * 60)
        let door = check("Front door locked", in: daily)
        let pill = check("Pill taken", in: daily)
        let planned = ReminderPlanner.plan(
            checks: [door, pill], categories: [daily], latestLogs: [door.id: log(door, at: TestTime.date(2026, 10, 29, 8))],
            now: now, boundary: boundary
        )
        #expect(planned.first?.body == "1 left: Pill taken")
        #expect(planned.first?.checkID == pill.id)
    }

    @Test func skipsTodayOnceEverythingIsLogged() {
        let daily = category(reminder: 21 * 60)
        let pill = check("Pill taken", in: daily)
        let planned = ReminderPlanner.plan(
            checks: [pill], categories: [daily], latestLogs: [pill.id: log(pill, at: TestTime.date(2026, 10, 29, 8))],
            now: now, boundary: boundary
        )
        #expect(planned.map(\.fireDate) == [TestTime.date(2026, 10, 30, 21)])
    }

    @Test func skipsATimeAlreadyPast() {
        let daily = category(reminder: 9 * 60)
        let planned = ReminderPlanner.plan(
            checks: [check("Pill taken", in: daily)], categories: [daily], latestLogs: [:], now: now, boundary: boundary
        )
        #expect(planned.map(\.fireDate) == [TestTime.date(2026, 10, 30, 9)])
    }

    @Test func remindsOnlyOnDaysTheCategoryIsDue() {
        // Thursday, Oct 29; the bins go out on Fridays.
        let bins = category(reminder: 20 * 60, rule: .weekly(weekday: 6))
        let planned = ReminderPlanner.plan(
            checks: [check("Bins out", in: bins)], categories: [bins], latestLogs: [:], now: now, boundary: boundary
        )
        #expect(planned.map(\.fireDate) == [TestTime.date(2026, 10, 30, 20)])
    }

    @Test func staysWithinTheBudgetNearestFirst() {
        let categories = (0..<40).map { category(reminder: 12 * 60 + $0) }
        let checks = categories.enumerated().map { check("Check \($0.offset)", in: $0.element) }
        let planned = ReminderPlanner.plan(checks: checks, categories: categories, latestLogs: [:], now: now, boundary: boundary)
        #expect(planned.count == ReminderPlanner.budget)
        #expect(planned.map(\.fireDate) == planned.map(\.fireDate).sorted())
        #expect(Set(planned.map(\.identifier)).count == planned.count)
    }

    @Test func noReminderOrNoTasksMeansNothing() {
        let quiet = category(reminder: nil)
        let empty = category(reminder: 21 * 60)
        let planned = ReminderPlanner.plan(
            checks: [check("Stove off", in: quiet)], categories: [quiet, empty], latestLogs: [:], now: now, boundary: boundary
        )
        #expect(planned.isEmpty)
    }
}

struct LeaveHomeNudgeTests {
    private let time = TestTime.relativeTime()
    private let now = TestTime.date(2026, 10, 29, 10, 51)

    @Test func nudgesUnloggedChecksOnly() {
        let door = check("Front door locked", nudge: true)
        let stove = check("Stove off", nudge: true)
        let pill = check("Pill taken")
        let nudges = LeaveHomeNudge.notifications(
            checks: [door, stove, pill], dueIDs: [door.id, stove.id, pill.id], latestLogs: [door.id: log(door, at: TestTime.date(2026, 10, 29, 8, 42))],
            now: now, time: time, reassures: false
        )
        #expect(nudges.map(\.checkID) == [stove.id])
    }

    @Test func aTaskNotDueTodayDoesntNudge() {
        let bins = check("Bins out", nudge: true)
        let nudges = LeaveHomeNudge.notifications(checks: [bins], dueIDs: [], latestLogs: [:], now: now, time: time, reassures: false)
        #expect(nudges.isEmpty)
        #expect(nudges.first?.title == "Leaving home? Stove off")
    }

    @Test func reassuresWhenAsked() {
        let door = check("Front door locked", nudge: true)
        let nudges = LeaveHomeNudge.notifications(
            checks: [door], dueIDs: [door.id], latestLogs: [door.id: log(door, at: TestTime.date(2026, 10, 29, 8, 42))],
            now: now, time: time, reassures: true
        )
        #expect(nudges.first?.title.plainSpaces == "Front door locked — 8:42 AM")
        #expect(nudges.first?.body == "You already checked. You’re good.")
    }

    @Test func yesterdaysLogStillNudges() {
        let door = check("Front door locked", nudge: true)
        let nudges = LeaveHomeNudge.notifications(
            checks: [door], dueIDs: [door.id], latestLogs: [door.id: log(door, at: TestTime.date(2026, 10, 28, 22))],
            now: now, time: time, reassures: true
        )
        #expect(nudges.first?.title == "Leaving home? Front door locked")
    }
}

final class FakeNotificationCenter: NotificationScheduling {
    private(set) var pending: [String: PlannedReminder] = [:]
    private(set) var posted: [PlannedReminder] = []

    func pendingIdentifiers() async -> [String] { Array(pending.keys) }

    func add(_ reminder: PlannedReminder, immediately: Bool) async {
        if immediately { posted.append(reminder) } else { pending[reminder.identifier] = reminder }
    }

    func removePending(_ identifiers: [String]) {
        identifiers.forEach { pending[$0] = nil }
    }
}

@MainActor
struct ReminderSchedulerTests {
    @Test func loggingRemovesTodaysPendingReminder() async {
        let center = FakeNotificationCenter()
        let scheduler = ReminderScheduler(center: center)
        let boundary = DayBoundary(calendar: TestTime.calendar())
        let daily = category(reminder: 21 * 60)
        let pill = check("Pill taken", in: daily)
        let now = TestTime.date(2026, 10, 29, 10)

        await scheduler.reschedule(checks: [pill], categories: [daily], latestLogs: [:], now: now, boundary: boundary)
        #expect(center.pending.count == 2)

        await scheduler.reschedule(
            checks: [pill], categories: [daily], latestLogs: [pill.id: log(pill, at: now)], now: now, boundary: boundary
        )
        #expect(center.pending.values.map(\.fireDate) == [TestTime.date(2026, 10, 30, 21)])
    }

    @Test func turningTheReminderOffClearsIt() async {
        let center = FakeNotificationCenter()
        let scheduler = ReminderScheduler(center: center)
        let boundary = DayBoundary(calendar: TestTime.calendar())
        var daily = category(reminder: 21 * 60)
        let pill = check("Pill taken", in: daily)
        let now = TestTime.date(2026, 10, 29, 10)
        await scheduler.reschedule(checks: [pill], categories: [daily], latestLogs: [:], now: now, boundary: boundary)
        daily.reminderMinutes = nil
        await scheduler.reschedule(checks: [pill], categories: [daily], latestLogs: [:], now: now, boundary: boundary)
        #expect(center.pending.isEmpty)
    }
}
