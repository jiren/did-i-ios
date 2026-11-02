import XCTest

final class StatsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOpeningFromTheTabBarAndChangingRange() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample"])
        let tab = app.buttons["tabbar.stats"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
        XCTAssertTrue(element(app, "stats.streak").waitForExistence(timeout: 5))
        XCTAssertTrue(element(app, "stats.average").exists)
        let tip = app.staticTexts["stats.tip"]
        XCTAssertTrue(tip.label.hasPrefix("Today"))
        app.buttons["stats.range.month"].tap()
        XCTAssertTrue(app.buttons["stats.range.month"].isSelected)
        XCTAssertTrue(tip.label.hasPrefix("This week"))
        app.buttons["stats.range.year"].tap()
        XCTAssertTrue(tip.label.contains("so far"))
    }

    @MainActor
    func testTappingABarReadsIt() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample", "-Open", "stats"])
        let tip = app.staticTexts["stats.tip"]
        XCTAssertTrue(tip.waitForExistence(timeout: 5))
        XCTAssertTrue(tip.label.hasPrefix("Today"))
        element(app, "stats.chart").coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.5)).tap()
        XCTAssertFalse(tip.label.hasPrefix("Today"))
    }

    @MainActor
    func testAnEmptyStoreSaysSo() throws {
        let app = XCUIApplication.launched(arguments: ["-Open", "stats"])
        XCTAssertTrue(element(app, "stats.empty").waitForExistence(timeout: 5))
        XCTAssertFalse(element(app, "stats.streak").exists)
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }
}
