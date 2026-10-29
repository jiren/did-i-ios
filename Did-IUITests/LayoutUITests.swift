import XCTest

final class LayoutUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTodayAtAnAccessibilityTextSize() throws {
        let app = XCUIApplication.launched(arguments: [
            "-SeedSample", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL",
        ])
        let first = app.buttons["tile.Front door locked"]
        let second = app.buttons["tile.Pill taken"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        // One column: the second tile sits below the first, not beside it.
        XCTAssertGreaterThan(second.frame.minY, first.frame.maxY - 1)
        XCTAssertTrue(app.buttons["tabbar.add"].isHittable)
    }

    @MainActor
    func testIPadShowsTheCheckBesideToday() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only")
        let app = XCUIApplication.launched(arguments: ["-SeedSample", "-Open", "detail"])
        XCTAssertTrue(app.buttons["tile.Front door locked"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["detail.logAgain"].exists)
    }
}
