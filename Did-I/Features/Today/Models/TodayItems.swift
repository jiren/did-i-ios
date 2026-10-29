import Foundation

/// A tile on Today.
struct TodayTile: Identifiable, Equatable {
    let id: UUID
    var content: CheckTileContent
}

/// A row in Today's Recent list.
struct RecentRow: Identifiable, Equatable {
    let id: UUID
    let checkID: UUID
    var title: String
    var meta: String
    var swatch: TileSwatch
}

/// The toast after a log, with what Undo reverses.
struct LogToast: Identifiable, Equatable {
    let id = UUID()
    var message: String
    var outcome: LogOutcome
}
