import XCTest

final class SettingsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testChangingTheAppearanceSticks() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample"])
        app.buttons["today.settings"].tap()
        let dark = app.segmentedControls["settings.appearance"].buttons["Dark"]
        XCTAssertTrue(dark.waitForExistence(timeout: 3))
        dark.tap()
        XCTAssertTrue(dark.isSelected)
        app.buttons["Back to Today"].tap()
        app.buttons["today.settings"].tap()
        XCTAssertTrue(app.segmentedControls["settings.appearance"].buttons["Dark"].isSelected)
    }

    @MainActor
    func testPickingTheCheckAPressLogs() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample", "-Open", "settings"])
        let row = app.buttons["settings.actionButton"]
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        row.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Pill taken")).firstMatch.tap()
        app.buttons["Back to Settings"].tap()
        XCTAssertTrue(app.buttons["settings.actionButton"].label.contains("Pill taken"))
    }
}
