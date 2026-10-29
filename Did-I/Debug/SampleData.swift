#if DEBUG
import Foundation

/// The design's four checks (`Main.dc.html`), three logged this morning. Launch with `-SeedSample`.
enum SampleData {
    static func seed(into store: SwiftDataStore, now: Date) {
        guard (try? store.checks().isEmpty) == true else { return }
        let added = (try? store.addChecks([
            CheckDraft(name: "Front door locked"),
            CheckDraft(name: "Pill taken"),
            CheckDraft(name: "Stove off"),
            CheckDraft(name: "Iron unplugged"),
        ])) ?? []
        // Keep the morning's logs inside today, even just after midnight.
        let sinceMidnight = now.timeIntervalSince(Calendar.current.startOfDay(for: now))
        let secondsAgo: [TimeInterval] = [129, 156, 141].map { min($0 * 60, sinceMidnight * Double($0) / 160) }
        for (check, seconds) in zip(added, secondsAgo) {
            _ = try? store.log(check.id, source: .app, at: now.addingTimeInterval(-seconds), photoFileName: nil)
        }
        if let door = added.first {
            _ = try? store.log(door.id, source: .lockScreenWidget, at: now.addingTimeInterval(-12 * 3600), photoFileName: nil)
        }
    }
}
#endif
