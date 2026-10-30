import Foundation

/// How Today shows a category's tasks (`Main.dc.html`'s view toggle).
nonisolated enum TodayLayout: String, CaseIterable, Sendable {
    case grid, list
}

/// Where Today's layout is kept: `AppSettings` in the app, a stub in tests.
protocol TodayLayoutStoring: AnyObject {
    var todayLayout: TodayLayout { get set }
}
