import Foundation

/// A category's section on Today: its heading and its tiles.
struct TodaySection: Identifiable, Equatable {
    var category: CategoryRecord
    var repeatLabel: String
    /// "2/4".
    var progressText: String
    var tiles: [TodayTile]

    var id: UUID { category.id }
}

/// A task's tile on Today.
struct TodayTile: Identifiable, Equatable {
    let id: UUID
    var content: TaskTileContent
}

/// The toast after a log, with what Undo reverses.
struct LogToast: Identifiable, Equatable {
    let id = UUID()
    var message: String
    var outcome: LogOutcome
}
