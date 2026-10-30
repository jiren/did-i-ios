import Foundation
@testable import Did_I

final class ChangeSpy: ChangeNotifying {
    private(set) var count = 0
    func didChange() { count += 1 }
}

final class FixedDays: DayBoundaryProviding {
    var dayBoundary: DayBoundary
    init(startHour: Int = 0) { dayBoundary = DayBoundary(calendar: TestTime.calendar(), startHour: startHour) }
}

final class LayoutSpy: TodayLayoutStoring {
    var todayLayout: TodayLayout = .grid
}
