import Foundation

/// The current time, injected so "today" and "2h ago" can be tested.
nonisolated protocol TimeSource: Sendable {
    var now: Date { get }
}

nonisolated struct SystemTimeSource: TimeSource {
    var now: Date { Date() }
}
