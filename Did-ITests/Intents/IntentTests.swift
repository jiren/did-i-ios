import AppIntents
import Foundation
import Testing
@testable import Did_I

struct LastLogAnswerTests {
    private let time = TestTime.relativeTime()
    private let now = TestTime.date(2026, 10, 29, 10, 51)

    @Test func loggedToday() {
        let answer = LastLogAnswer.text(checkName: "Front door locked", latest: TestTime.date(2026, 10, 29, 8, 42), now: now, time: time)
        #expect(answer.plainSpaces == "Yes. Front door locked at 8:42 AM, 2h 9m ago.")
    }

    @Test func loggedYesterday() {
        let answer = LastLogAnswer.text(checkName: "Pill taken", latest: TestTime.date(2026, 10, 28, 22, 58), now: now, time: time)
        #expect(answer.plainSpaces == "Not yet today. The last time was Yesterday, 10:58 PM.")
    }

    @Test func neverLogged() {
        #expect(LastLogAnswer.text(checkName: "Stove off", latest: nil, now: now, time: time) == "You haven’t logged Stove off yet.")
    }

    @Test func notDueToday() {
        let answer = LastLogAnswer.text(
            checkName: "Bins out", latest: TestTime.date(2026, 10, 23, 7, 5), now: now, time: time, isDueToday: false
        )
        #expect(answer.plainSpaces.hasPrefix("Not due today. Last done "))
        #expect(answer.plainSpaces.hasSuffix("7:05 AM."))
        #expect(LastLogAnswer.text(checkName: "Bins out", latest: nil, now: now, time: time, isDueToday: false) == "Bins out isn’t due today.")
    }

    @Test func aLogTodayAnswersYesEvenWhenNotDue() {
        let answer = LastLogAnswer.text(
            checkName: "Bins out", latest: TestTime.date(2026, 10, 29, 8, 42), now: now, time: time, isDueToday: false
        )
        #expect(answer.hasPrefix("Yes."))
    }
}

/// Intents read `IntentServices.shared`, so these run one at a time with their own store.
@MainActor
@Suite(.serialized)
struct IntentPerformTests {
    private let clock = FixedTimeSource(TestTime.date(2026, 10, 29, 8, 42))
    private let store: SwiftDataStore
    private let settings: AppSettings
    private let checks: [CheckRecord]

    init() throws {
        store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
        settings = AppSettings(defaults: UserDefaults(suiteName: "IntentPerformTests-\(UUID().uuidString)")!)
        checks = try store.addChecks([CheckDraft(name: "Front door locked"), CheckDraft(name: "Pill taken")])
        IntentServices.shared = IntentServices(
            store: store, settings: settings,
            photos: PhotoStore(folder: URL.temporaryDirectory.appending(path: "IntentPerformTests-\(UUID().uuidString)")),
            timeSource: clock
        ) {}
    }

    @Test func logCheckIntentLogsFromShortcuts() async throws {
        let intent = LogCheckIntent(check: CheckEntity(checks[0]))
        _ = try await intent.perform()
        let log = try #require(try store.latestLogs()[checks[0].id])
        #expect(log.source == .shortcut)
        #expect(log.date == clock.now)
    }

    @Test func widgetLogIntentRecordsItsSource() async throws {
        _ = try await WidgetLogIntent(checkID: checks[1].id, source: .homeScreenWidget).perform()
        #expect(try store.latestLogs()[checks[1].id]?.source == .homeScreenWidget)
    }

    @Test func undoLogIntentDeletesTheLog() async throws {
        let logged = try CheckLogger.log(checks[0].id, source: .actionButton)
        _ = try await UndoLogIntent(logID: logged.logID).perform()
        #expect(try store.logCount(for: checks[0].id) == 0)
    }

    @Test func actionButtonLogsThePickedCheck() async throws {
        settings.actionButtonCheckID = checks[1].id
        _ = try await ActionButtonPressIntent().perform()
        #expect(try store.latestLogs()[checks[1].id]?.source == .actionButton)
        #expect(try store.latestLogs()[checks[0].id] == nil)
    }

    @Test func entityQueryMatchesWords() async throws {
        let matches = try await CheckEntityQuery().entities(matching: "door")
        #expect(matches.map(\.name) == ["Front door locked"])
        #expect(try await CheckEntityQuery().entities(for: [checks[1].id]).map(\.name) == ["Pill taken"])
    }

    @Test func askMeWhichListsTodaysDueTasksFirst() async throws {
        // Sunday, Nov 1 is never today in these tests' week, so its category isn't due.
        let sunday = try store.addCategory(
            CategoryDraft(name: "Sunday", rule: .once(CalendarDay(year: 2026, month: 11, day: 1))),
            tasks: [CheckDraft(name: "Plants watered")]
        )
        try store.moveCheck(checks[0].id, to: sunday.id)
        let suggested = try await CheckEntityQuery().suggestedEntities()
        #expect(suggested.map(\.name) == ["Pill taken", "Plants watered", "Front door locked"])
    }

    @Test func entitiesShowTheirCategory() async throws {
        let bedtime = try store.addCategory(CategoryDraft(name: "Bedtime"), tasks: [CheckDraft(name: "Front door locked")])
        let matches = try await CheckEntityQuery().entities(matching: "front door")
        #expect(matches.count == 2)
        #expect(Set(matches.compactMap(\.category)) == ["Daily", bedtime.name])
    }

    @Test func checkLoggerDescribesTheLog() throws {
        let logged = try CheckLogger.log(checks[0].id, source: .siri)
        #expect(logged.checkName == "Front door locked")
        #expect(logged.dialog.hasPrefix("Logged Front door locked at"))
    }
}

@MainActor
struct LoggedViewModelTests {
    @Test func showsThePressAndUndoes() throws {
        let clock = FixedTimeSource(TestTime.date(2026, 10, 29, 8, 42, 7))
        let store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
        let check = try store.addChecks([CheckDraft(name: "Front door locked")])[0]
        let outcome = try store.log(check.id, source: .actionButton, at: clock.now, photoFileName: nil)
        let changes = ChangeSpy()
        let viewModel = LoggedViewModel(
            request: LoggedRequest(logID: outcome.record.id, opensCamera: false),
            store: store, days: FixedDays(), changes: changes, photos: nil, locale: Locale(identifier: "en_US")
        )
        viewModel.load()
        #expect(viewModel.sourceText == "Logged with Action Button")
        #expect(viewModel.title == "Front door locked.")
        #expect(viewModel.whenText.plainSpaces == "Thursday · 8:42:07 AM")

        viewModel.undo()
        #expect(viewModel.isUndone)
        #expect(try store.logCount(for: check.id) == 0)
        #expect(changes.count == 1)
    }
}
