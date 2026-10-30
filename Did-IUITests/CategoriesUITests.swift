import XCTest

final class CategoriesUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// A weekly category starts on today's weekday, so it shows on Today straight away.
    @MainActor
    func testCreatingAWeeklyCategoryAndAddingToIt() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample", "-Open", "newCategory"])
        let name = app.textFields["category.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Gym")
        app.buttons["category.repeat.weekly"].tap()
        let task = app.textFields["category.task"]
        task.tap()
        task.typeText("Water bottle\n")
        task.typeText("Towel packed\n")
        app.buttons["category.save"].tap()

        XCTAssertTrue(app.buttons["tile.Water bottle"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["tile.Towel packed"].exists)

        let add = app.buttons["section.Gym.add"]
        add.tap()
        XCTAssertTrue(app.buttons["addChecks.chip.Keys packed"].waitForExistence(timeout: 3))
        app.buttons["addChecks.chip.Keys packed"].tap()
        XCTAssertEqual(app.buttons["addChecks.commit"].label, "Add 1 task to Gym")
        app.buttons["addChecks.commit"].tap()
        XCTAssertTrue(app.buttons["tile.Keys packed"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testMovingATaskAndDeletingACategoryBothWays() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample"])
        let bins = app.buttons["tile.Bins out"]
        XCTAssertTrue(bins.waitForExistence(timeout: 5))

        // Move a task: Bin night → Daily.
        app.buttons["tile.Recycling out"].press(forDuration: 1.0)
        app.buttons["Move to"].firstMatch.tap()
        app.buttons["Daily"].firstMatch.tap()
        app.buttons["filter.Daily"].tap()
        XCTAssertTrue(app.buttons["tile.Recycling out"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["tile.Bins out"].exists)
        app.buttons["filter.all"].tap()

        // Delete Bin night, moving its task to Daily.
        app.descendants(matching: .any)["section.Bin night"].firstMatch.press(forDuration: 1.0)
        app.buttons["Delete category"].firstMatch.tap()
        app.buttons["category.delete.move"].firstMatch.tap()
        XCTAssertFalse(app.descendants(matching: .any)["section.Bin night"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["tile.Bins out"].exists)

        // Delete Travel with its tasks, from Settings › Categories.
        app.buttons["today.settings"].tap()
        app.buttons["settings.categories"].tap()
        let travel = app.buttons["categories.row.Travel"]
        XCTAssertTrue(travel.waitForExistence(timeout: 3))
        travel.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        app.buttons["category.delete.tasks"].firstMatch.tap()
        XCTAssertFalse(travel.waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["categories.row.Daily"].exists)
    }
}
