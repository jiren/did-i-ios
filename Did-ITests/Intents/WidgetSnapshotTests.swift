import Foundation
import Testing
@testable import Did_I

@MainActor
struct WidgetSnapshotTests {
    @Test func readsTodaysStateAndTheDayEnd() throws {
        let clock = FixedTimeSource(TestTime.date(2026, 10, 29, 10, 51))
        let store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
        let defaults = UserDefaults(suiteName: "WidgetSnapshotTests-\(UUID().uuidString)")!
        let settings = AppSettings(defaults: defaults)
        settings.hidesNamesOnLockScreen = true
        let checks = try store.addChecks([CheckDraft(name: "Front door locked"), CheckDraft(name: "Pill taken")])
        _ = try store.log(checks[0].id, source: .app, at: TestTime.date(2026, 10, 29, 8, 42), photoFileName: nil)
        _ = try store.log(checks[1].id, source: .app, at: TestTime.date(2026, 10, 28, 22, 58), photoFileName: nil)
        let services = IntentServices(store: store, settings: settings, photos: PhotoStore(), timeSource: clock) {}

        let snapshot = WidgetSnapshot.read(services: services, now: clock.now)
        #expect(snapshot.checks.map(\.loggedToday) == [TestTime.date(2026, 10, 29, 8, 42), nil])
        #expect(snapshot.checks.map(\.swatch) == [.violet, .sun])
        #expect(snapshot.hidesNames)
        #expect(snapshot.nextDayStart > clock.now)
    }
}
