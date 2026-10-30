#if DEBUG
import Foundation

/// The design's categories and tasks (`Main.dc.html`), with the door, pill, stove and bins logged this morning.
/// Bin night is due today, Home safety in two days and Travel in three, as on the design's Friday. Launch with
/// `-SeedSample`.
enum SampleData {
    static func seed(into store: SwiftDataStore, now: Date) {
        guard (try? store.checks().isEmpty) == true else { return }
        let calendar = Calendar.current
        let today = CalendarDay(now, calendar: calendar)
        let inTwoDays = today.adding(days: 2, calendar: calendar)
        let daily = (try? store.addChecks([
            CheckDraft(name: "Front door locked"),
            CheckDraft(name: "Pill taken"),
            CheckDraft(name: "Stove off"),
            CheckDraft(name: "Iron unplugged"),
        ])) ?? []
        _ = try? store.addCategory(
            CategoryDraft(name: "Bin night", icon: .bin, colour: .mint, rule: .weekly(weekday: today.weekday(in: calendar))),
            tasks: [CheckDraft(name: "Bins out", kind: .other), CheckDraft(name: "Recycling out", kind: .other)]
        )
        _ = try? store.addCategory(
            CategoryDraft(name: "Home safety", icon: .home, colour: .coral, rule: .monthly(day: inTwoDays.day)),
            tasks: [CheckDraft(name: "Smoke alarm tested", kind: .stove), CheckDraft(name: "Extinguisher checked", kind: .other)]
        )
        _ = try? store.addCategory(
            CategoryDraft(name: "Travel", icon: .suitcase, colour: .sky, rule: .once(today.adding(days: 3, calendar: calendar))),
            tasks: ["Passport packed", "Charger packed", "Windows closed", "Water main off"].map { CheckDraft(name: $0) }
        )
        let bins = (try? store.checks().first { $0.name == "Bins out" }).flatMap { $0 }

        // Keep the morning's logs inside today, even just after midnight.
        let sinceMidnight = now.timeIntervalSince(calendar.startOfDay(for: now))
        let minutesAgo: [TimeInterval] = [120, 147, 132, 217]
        let morning = Array(daily.prefix(3)) + [bins].compactMap { $0 }
        for (check, minutes) in zip(morning, minutesAgo) {
            let seconds = min(minutes * 60, sinceMidnight * minutes / 240)
            _ = try? store.log(check.id, source: .app, at: now.addingTimeInterval(-seconds), photoFileName: nil)
        }
        // Last night at 10:58 PM, as in `Detail.dc.html`, whatever the time now.
        if let door = daily.first {
            let lastNight = calendar.startOfDay(for: now).addingTimeInterval(-62 * 60)
            _ = try? store.log(door.id, source: .lockScreenWidget, at: lastNight, photoFileName: nil)
        }
    }
}
#endif
