import BackgroundTasks
import Foundation

/// The background refresh that reschedules reminders around the day change.
enum BackgroundRefresh {
    static let identifier = "com.elo.Did-I.reminders"

    static func schedule(after date: Date) {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = date
        Task { try? await BGTaskScheduler.shared.submitTaskRequest(request) }
    }
}
