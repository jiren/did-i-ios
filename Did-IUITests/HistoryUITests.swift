import XCTest

final class HistoryUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLoggingFromDetail() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample", "-Open", "detail"])
        let count = app.staticTexts["detail.count"]
        XCTAssertTrue(count.waitForExistence(timeout: 5))
        XCTAssertEqual(count.label, "2 logs")
        app.buttons["detail.logAgain"].tap()
        XCTAssertEqual(app.staticTexts["detail.count"].label, "3 logs")
    }

    @MainActor
    func testDeletingALogFromHistory() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample", "-Open", "history"])
        let firstRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Front door locked'")).firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5))
        let before = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Front door locked'")).count
        firstRow.swipeLeft()
        app.buttons["Delete"].tap()
        let after = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Front door locked'")).count
        XCTAssertEqual(after, before - 1)
    }
}
