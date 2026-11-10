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

    @MainActor
    func testALaterDayIsUpcoming() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample"])
        let tile = app.buttons["tile.Iron unplugged"]
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        // Tomorrow: the sample's Bin night is due today, so only Daily is.
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'strip.' AND identifier != 'strip.today'"))
            .element(boundBy: 0).tap()
        XCTAssertTrue(tile.label.contains("upcoming"))
        XCTAssertFalse(app.buttons["tile.Iron unplugged.photo"].exists)
        tile.tap()
        XCTAssertFalse(app.descendants(matching: .any)["today.toast"].waitForExistence(timeout: 1))
        XCTAssertFalse(app.buttons["tile.Bins out"].exists)
    }

    @MainActor
    func testTappingTodayReturnsToToday() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample"])
        let tile = app.buttons["tile.Iron unplugged"]
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'strip.' AND identifier != 'strip.today'"))
            .element(boundBy: 0).tap()
        XCTAssertTrue(tile.label.contains("upcoming"))
        app.buttons["tabbar.today"].tap()
        XCTAssertTrue(tile.label.contains("not logged"))
        XCTAssertTrue(app.buttons["tile.Bins out"].exists)
    }

    @MainActor
    func testListLayoutLogsARow() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample"])
        let row = app.buttons["tile.Iron unplugged"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        app.buttons["today.layout"].tap()
        XCTAssertEqual(app.buttons["today.layout"].label, "Show as grid")
        XCTAssertTrue(row.label.contains("not logged"))
        row.tap()
        XCTAssertTrue(app.descendants(matching: .any)["today.toast"].waitForExistence(timeout: 2))
        XCTAssertFalse(row.label.contains("not logged"))
    }

    @MainActor
    func testCollapsingASection() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample"])
        let tile = app.buttons["tile.Front door locked"]
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        let header = app.buttons["section.Daily"]
        XCTAssertEqual(header.value as? String, "Expanded")
        header.tap()
        XCTAssertFalse(tile.waitForExistence(timeout: 1))
        XCTAssertEqual(header.value as? String, "Collapsed")
        header.tap()
        XCTAssertTrue(tile.waitForExistence(timeout: 2))
    }

    @MainActor
    func testFilteringByACategory() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample"])
        XCTAssertTrue(app.buttons["tile.Bins out"].waitForExistence(timeout: 5))
        app.buttons["filter.Bin night"].tap()
        XCTAssertTrue(app.buttons["tile.Bins out"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["tile.Front door locked"].exists)
        app.buttons["filter.all"].tap()
        XCTAssertTrue(app.buttons["tile.Front door locked"].waitForExistence(timeout: 2))
    }

    /// The sample's Bin night is Evening and Daily Anytime, so Today shows both headers; one category alone shows none.
    @MainActor
    func testPartOfDayHeaders() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample"])
        XCTAssertTrue(app.staticTexts["today.part.evening"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["today.part.anytime"].exists)
        app.buttons["filter.Bin night"].tap()
        XCTAssertTrue(app.buttons["tile.Bins out"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["today.part.evening"].exists)
    }
}

final class PhotoUITests: XCTestCase {
    @MainActor
    func testLoggingWithASamplePhotoInTheSimulator() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample"])
        let camera = app.buttons["tile.Iron unplugged.photo"]
        XCTAssertTrue(camera.waitForExistence(timeout: 5))
        camera.tap()
        let sample = app.buttons["photo.action"]
        XCTAssertTrue(sample.waitForExistence(timeout: 3))
        sample.tap()
        XCTAssertTrue(app.descendants(matching: .any)["today.toast"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["tile.Iron unplugged.photo"].label, "Retake photo for Iron unplugged")
    }
}
