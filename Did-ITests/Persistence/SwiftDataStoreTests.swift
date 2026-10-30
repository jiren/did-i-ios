import Foundation
import SwiftData
import Testing
@testable import Did_I

@MainActor
struct SwiftDataStoreTests {
    private let clock = FixedTimeSource(TestTime.date(2026, 10, 29, 8, 0))
    private let store: SwiftDataStore

    init() throws {
        store = SwiftDataStore(container: try .app(inMemory: true), timeSource: clock)
    }

    private func addDoorAndPill() throws -> (door: CheckRecord, pill: CheckRecord) {
        let added = try store.addChecks([CheckDraft(name: "Front door locked"), CheckDraft(name: "Pill taken")])
        return (added[0], added[1])
    }

    @Test func addsChecksInOrderAndSkipsDuplicates() throws {
        _ = try addDoorAndPill()
        try store.addChecks([CheckDraft(name: " front door locked"), CheckDraft(name: ""), CheckDraft(name: "Stove off")])
        let checks = try store.checks()
        #expect(checks.map(\.name) == ["Front door locked", "Pill taken", "Stove off"])
        #expect(checks.map(\.order) == [0, 1, 2])
        #expect(checks[0].kind == .door)
    }

    @Test func renamesAndChangesKind() throws {
        let (door, _) = try addDoorAndPill()
        try store.rename(door.id, to: "  Back door locked ")
        try store.setKind(.garage, for: door.id)
        let check = try #require(try store.check(id: door.id))
        #expect(check.name == "Back door locked")
        #expect(check.kind == .garage)
    }

    @Test func reorders() throws {
        let (door, pill) = try addDoorAndPill()
        let stove = try store.addChecks([CheckDraft(name: "Stove off")])[0]
        try store.reorder([stove.id, door.id])
        #expect(try store.checks().map(\.id) == [stove.id, door.id, pill.id])
    }

    @Test func removingACheckRemovesItsLogsAndReturnsPhotos() throws {
        let (door, pill) = try addDoorAndPill()
        _ = try store.log(door.id, source: .app, at: clock.now, photoFileName: "a.heic")
        _ = try store.log(pill.id, source: .app, at: clock.now, photoFileName: nil)
        #expect(try store.removeCheck(door.id) == ["a.heic"])
        #expect(try store.logs(for: nil, limit: nil).map(\.checkID) == [pill.id])
    }

    @Test func logsAppend() throws {
        let (door, _) = try addDoorAndPill()
        _ = try store.log(door.id, source: .app, at: clock.now, photoFileName: nil)
        let second = try store.log(door.id, source: .lockScreenWidget, at: clock.now.addingTimeInterval(60), photoFileName: nil)
        guard case .added = second else { Issue.record("expected a new log"); return }
        #expect(try store.logCount(for: door.id) == 2)
        #expect(try store.latestLogs()[door.id]?.source == .lockScreenWidget)
    }

    @Test func aRepeatWithinTenSecondsRefreshesTheLastLog() throws {
        let (door, _) = try addDoorAndPill()
        let first = try store.log(door.id, source: .app, at: clock.now, photoFileName: nil)
        let repeatLog = try store.log(door.id, source: .lockScreenWidget, at: clock.now.addingTimeInterval(9), photoFileName: "p.heic")
        guard case .refreshed(let record, let previous) = repeatLog else { Issue.record("expected a refresh"); return }
        #expect(previous == first.record)
        #expect(record.date == clock.now.addingTimeInterval(9))
        #expect(record.photoFileName == "p.heic")
        #expect(try store.logCount(for: door.id) == 1)

        try store.undo(repeatLog)
        #expect(try store.logs(for: door.id, limit: nil) == [first.record])
    }

    @Test func elevenSecondsLaterAddsALog() throws {
        let (door, _) = try addDoorAndPill()
        _ = try store.log(door.id, source: .app, at: clock.now, photoFileName: nil)
        _ = try store.log(door.id, source: .app, at: clock.now.addingTimeInterval(11), photoFileName: nil)
        #expect(try store.logCount(for: door.id) == 2)
    }

    @Test func undoingAnAddedLogDeletesIt() throws {
        let (door, _) = try addDoorAndPill()
        let outcome = try store.log(door.id, source: .app, at: clock.now, photoFileName: nil)
        try store.undo(outcome)
        #expect(try store.logCount(for: door.id) == 0)
    }

    @Test func logsInARange() throws {
        let (door, pill) = try addDoorAndPill()
        _ = try store.log(door.id, source: .app, at: TestTime.date(2026, 10, 28, 22), photoFileName: nil)
        _ = try store.log(pill.id, source: .app, at: TestTime.date(2026, 10, 29, 8), photoFileName: nil)
        let today = try store.logs(from: TestTime.date(2026, 10, 29), to: TestTime.date(2026, 10, 30))
        #expect(today.map(\.checkID) == [pill.id])
    }

    @Test func deletesALogAndReturnsItsPhoto() throws {
        let (door, _) = try addDoorAndPill()
        let outcome = try store.log(door.id, source: .app, at: clock.now, photoFileName: "x.heic")
        #expect(try store.deleteLog(outcome.record.id) == "x.heic")
        #expect(throws: StoreError.logNotFound) { try store.deleteLog(outcome.record.id) }
    }

    @Test func clearsOldPhotosAndDeletesEverything() throws {
        let (door, pill) = try addDoorAndPill()
        _ = try store.log(door.id, source: .app, at: TestTime.date(2026, 9, 1), photoFileName: "old.heic")
        _ = try store.log(pill.id, source: .app, at: TestTime.date(2026, 10, 29), photoFileName: "new.heic")
        #expect(try store.clearPhotos(olderThan: TestTime.date(2026, 10, 1)) == ["old.heic"])
        #expect(try store.photoFileNames() == ["new.heic"])
        #expect(try store.deleteEverything() == ["new.heic"])
        #expect(try store.checks().isEmpty)
    }

    @Test func setsTheNudge() throws {
        let (door, _) = try addDoorAndPill()
        try store.setNudgesOnLeavingHome(true, for: door.id)
        #expect(try #require(try store.check(id: door.id)).nudgesOnLeavingHome)
    }
}

@MainActor
struct SharedStoreFileTests {
    @Test func aWriteFromAnotherContainerIsSeenAfterReloading() throws {
        let url = URL.temporaryDirectory.appending(path: "DidI-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }
        let app = SwiftDataStore(container: try .app(url: url))
        let check = try app.addChecks([CheckDraft(name: "Front door locked")])[0]
        #expect(try app.logCount(for: check.id) == 0)

        let widget = SwiftDataStore(container: try .app(url: url))
        _ = try widget.log(check.id, source: .lockScreenWidget, at: Date(), photoFileName: nil)

        app.reloadFromDisk()
        #expect(try app.logCount(for: check.id) == 1)
        #expect(try app.latestLogs()[check.id]?.source == .lockScreenWidget)
    }
}
