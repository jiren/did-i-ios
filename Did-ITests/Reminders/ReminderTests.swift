import Foundation
import Testing
@testable import Did_I

private func check(_ name: String, reminder: Int? = nil, nudge: Bool = false) -> CheckRecord {
    CheckRecord(id: UUID(), name: name, kind: .other, order: 0, reminderMinutes: reminder, nudgesOnLeavingHome: nudge)
}

private func log(_ check: CheckRecord, at date: Date) -> LogRecord {
    LogRecord(id: UUID(), checkID: check.id, date: date, source: .app, photoFileName: nil)
}

struct ReminderPlannerTests {
    private let boundary = DayBoundary(calendar: TestTime.calendar())

    @Test func plansTodayAndTomorrowWhenNotLogged() {
        let pill = check("Pill taken", reminder: 21 * 60)
        let planned = ReminderPlanner.plan(checks: [pill], latestLogs: [:], now: TestTime.date(2026, 10, 29, 10), boundary: boundary)
        #expect(planned.map(\.fireDate) == [TestTime.date(2026, 10, 29, 21), TestTime.date(2026, 10, 30, 21)])
        #expect(planned.first?.title == "Pill taken")
    }

    @Test func skipsTodayOnceLogged() {
        let pill = check("Pill taken", reminder: 21 * 60)
        let planned = ReminderPlanner.plan(
            checks: [pill], latestLogs: [pill.id: log(pill, at: TestTime.date(2026, 10, 29, 8))],
            now: TestTime.date(2026, 10, 29, 10), boundary: boundary
        )
        #expect(planned.map(\.fireDate) == [TestTime.date(2026, 10, 30, 21)])
    }

    @Test func skipsATimeAlreadyPast() {
        let pill = check("Pill taken", reminder: 9 * 60)
        let planned = ReminderPlanner.plan(checks: [pill], latestLogs: [:], now: TestTime.date(2026, 10, 29, 10), boundary: boundary)
        #expect(planned.map(\.fireDate) == [TestTime.date(2026, 10, 30, 9)])
    }

    @Test func staysWithinTheBudgetNearestFirst() {
        let checks = (0..<40).map { check("Check \($0)", reminder: 12 * 60 + $0) }
        let planned = ReminderPlanner.plan(checks: checks, latestLogs: [:], now: TestTime.date(2026, 10, 29, 10), boundary: boundary)
        #expect(planned.count == ReminderPlanner.budget)
        #expect(planned.map(\.fireDate) == planned.map(\.fireDate).sorted())
        #expect(Set(planned.map(\.identifier)).count == planned.count)
    }

    @Test func checksWithoutARemindersAreLeftOut() {
        #expect(ReminderPlanner.plan(checks: [check("Stove off")], latestLogs: [:], now: Date(), boundary: boundary).isEmpty)
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
            checks: [door, stove, pill], latestLogs: [door.id: log(door, at: TestTime.date(2026, 10, 29, 8, 42))],
            now: now, time: time, reassures: false
        )
        #expect(nudges.map(\.checkID) == [stove.id])
        #expect(nudges.first?.title == "Leaving home? Stove off")
    }

    @Test func reassuresWhenAsked() {
        let door = check("Front door locked", nudge: true)
        let nudges = LeaveHomeNudge.notifications(
            checks: [door], latestLogs: [door.id: log(door, at: TestTime.date(2026, 10, 29, 8, 42))],
            now: now, time: time, reassures: true
        )
        #expect(nudges.first?.title.plainSpaces == "Front door locked — 8:42 AM")
        #expect(nudges.first?.body == "You already checked. You’re good.")
    }

    @Test func yesterdaysLogStillNudges() {
        let door = check("Front door locked", nudge: true)
        let nudges = LeaveHomeNudge.notifications(
            checks: [door], latestLogs: [door.id: log(door, at: TestTime.date(2026, 10, 28, 22))],
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
        let pill = check("Pill taken", reminder: 21 * 60)
        let now = TestTime.date(2026, 10, 29, 10)

        await scheduler.reschedule(checks: [pill], latestLogs: [:], now: now, boundary: boundary)
        #expect(center.pending.count == 2)

        await scheduler.reschedule(checks: [pill], latestLogs: [pill.id: log(pill, at: now)], now: now, boundary: boundary)
        #expect(center.pending.values.map(\.fireDate) == [TestTime.date(2026, 10, 30, 21)])
    }

    @Test func turningTheReminderOffClearsIt() async {
        let center = FakeNotificationCenter()
        let scheduler = ReminderScheduler(center: center)
        let boundary = DayBoundary(calendar: TestTime.calendar())
        let pill = check("Pill taken", reminder: 21 * 60)
        await scheduler.reschedule(checks: [pill], latestLogs: [:], now: TestTime.date(2026, 10, 29, 10), boundary: boundary)
        await scheduler.reschedule(checks: [check("Pill taken")], latestLogs: [:], now: TestTime.date(2026, 10, 29, 10), boundary: boundary)
        #expect(center.pending.isEmpty)
    }
}

@MainActor
struct DetailReminderTests {
    @Test func enablingDefaultsToNinePM() throws {
        let clock = FixedTimeSource(TestTime.date(2026, 10, 29, 10))
        let store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
        let changes = ChangeSpy()
        let pill = try store.addChecks([CheckDraft(name: "Pill taken")])[0]
        let viewModel = DetailViewModel(
            checkID: pill.id, checkStore: store, logStore: store, days: FixedDays(), timeSource: clock, changes: changes,
            editor: CheckEditor(store: store, changes: changes, photos: nil), photos: nil
        )
        viewModel.reload()
        #expect(viewModel.reminderDate == nil)
        viewModel.enableReminder()
        #expect(try store.check(id: pill.id)?.reminderMinutes == 21 * 60)
        #expect(viewModel.reminderDate == TestTime.date(2026, 10, 29, 21))
        viewModel.setReminder(nil)
        #expect(try store.check(id: pill.id)?.reminderMinutes == nil)
    }
}
