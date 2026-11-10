import Foundation

/// A category's section on Today: its heading and its tasks.
struct TodaySection: Identifiable, Equatable {
    var category: CategoryRecord
    /// "Every Friday", or "All done · last 8:42 AM".
    var meta: String
    /// "2/4", or "✓ 2/2" once all done.
    var progressText: String
    var isAllDone: Bool
    var isExpanded: Bool
    var tiles: [TodayTile]
    /// "Morning", above the first section of a part of the day, when the day spans two or more parts.
    var partHeader: PartOfDay? = nil

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
