import Foundation
import Testing
@testable import Did_I

struct TodaySummaryTests {
    private let checks = ["Front door locked", "Pill taken", "Stove off", "Iron unplugged"].enumerated().map {
        CheckRecord(id: UUID(), name: $1, kind: .other, order: $0, categoryID: CategoryDefaults.dailyID, nudgesOnLeavingHome: false)
    }

    @Test(arguments: [
        (4, "4 of 4 today", "All clear. Nothing to recheck."),
        (3, "3 of 4 today", "1 left: Iron unplugged"),
        (1, "1 of 4 today", "3 left to check"),
        (0, "0 of 4 today", "4 left to check"),
    ])
    func copy(done: Int, progress: String, summary: String) {
        let result = TodaySummary(checks: checks, doneIDs: Set(checks.prefix(done).map(\.id)))
        #expect(result.progressText == progress)
        #expect(result.summaryText == summary)
        #expect(result.isAllClear == (done == 4))
    }

    @Test func noChecksIsNotAllClear() {
        #expect(!TodaySummary(checks: [], doneIDs: []).isAllClear)
    }
}
