import XCTest

final class TodayUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testANewInstallShowsTheEmptyState() throws {
        let app = XCUIApplication.launched()
        XCTAssertTrue(app.buttons["today.empty.add"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLoggingACheckThenUndoing() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample"])
        let tile = app.buttons["tile.Iron unplugged"]
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        XCTAssertTrue(tile.label.contains("not logged"))

        tile.tap()
        XCTAssertTrue(app.descendants(matching: .any)["today.toast"].waitForExistence(timeout: 2))
        XCTAssertTrue(tile.label.contains("logged"))
        XCTAssertFalse(tile.label.contains("not logged"))

        app.buttons["toast.undo"].tap()
        XCTAssertTrue(app.buttons["tile.Iron unplugged"].label.contains("not logged"))
    }
}
