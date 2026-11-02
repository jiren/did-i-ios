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

    /// The sample, plus about two years of logs for Stats, the same on every run: fewer missed tasks and re-logs as
    /// time goes on, and nothing missed in the last 12 days, as the design's streak. Launch with `-SeedStats`.
    static func seedStats(into store: SwiftDataStore, now: Date) {
        seed(into: store, now: now)
        let calendar = Calendar.current
        guard let categories = try? store.categories(), let checks = try? store.checks() else { return }
        let rules = Dictionary(categories.map { ($0.id, $0.rule) }, uniquingKeysWith: { first, _ in first })
        let today = CalendarDay(now, calendar: calendar)
        let days = 730
        var logs: [LogRecord] = []
        for offset in 1...days {
            let day = today.adding(days: -offset, calendar: calendar)
            let age = Double(offset) / Double(days)
            for (index, check) in checks.enumerated() where (rules[check.categoryID] ?? .daily).isDue(on: day, calendar: calendar) {
                if offset > 12, roll(offset, index, 1) < 0.04 + age * 0.3 { continue }
                let hour = roll(offset, index, 2) < 0.2 ? 22 : 8
                let minute = Int(roll(offset, index, 3) * 59)
                guard let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day.noon(in: calendar)) else { continue }
                let photo = roll(offset, index, 4) < 0.1 ? "seed-\(offset)-\(index).heic" : nil
                logs.append(LogRecord(id: UUID(), checkID: check.id, date: date, source: source(roll(offset, index, 5)), photoFileName: photo))
                if roll(offset, index, 6) < (index == 2 ? 0.25 : 0.05) + age * 0.1 {
                    let again = date.addingTimeInterval(12 * 60)
                    logs.append(LogRecord(id: UUID(), checkID: check.id, date: again, source: source(roll(offset, index, 7)), photoFileName: nil))
                }
            }
        }
        try? store.insertLogsForDebugging(logs)
    }

    private static func source(_ roll: Double) -> LogSource {
        switch roll {
        case ..<0.50: .actionButton
        case ..<0.80: .lockScreenWidget
        case ..<0.95: .app
        case ..<0.98: .homeScreenWidget
        default: .siri
        }
    }

    /// 0 to 1, fixed for its inputs.
    private static func roll(_ day: Int, _ check: Int, _ salt: Int) -> Double {
        var value = UInt64(day &* 73_856_093) ^ UInt64(check &* 19_349_663) ^ UInt64(salt &* 83_492_791)
        value = (value ^ (value >> 13)) &* 0x5BD1_E995
        value ^= value >> 15
        return Double(value % 10_000) / 10_000
    }
}
#endif
