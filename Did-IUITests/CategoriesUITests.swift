import XCTest

final class CategoriesUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// A weekly category starts on today's weekday, so it shows on Today straight away.
    @MainActor
    func testCreatingAWeeklyCategoryAndAddingToIt() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample", "-Open", "newCategory"])
        XCTAssertTrue(app.buttons["templates.scratch"].waitForExistence(timeout: 5))
        app.buttons["templates.scratch"].tap()
        let name = app.textFields["category.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Gym")
        // Close the keyboard, as a person would, so it doesn't cover the fields below.
        app.buttons["category.keyboardDone"].tap()
        app.buttons["category.repeat.weekly"].tap()
        let task = app.textFields["category.task"]
        task.tap()
        task.typeText("Water bottle\n")
        task.typeText("Towel packed\n")
        app.buttons["category.keyboardDone"].tap()
        app.buttons["category.save"].tap()

        // The new section is last, and Today's stacks are lazy: scroll until it's built and clear of the tab bar.
        let water = app.buttons["tile.Water bottle"]
        let add = app.buttons["section.Gym.add"]
        let bar = app.buttons["tabbar.add"]
        XCTAssertTrue(bar.waitForExistence(timeout: 3))
        for _ in 0..<6 where !add.exists || add.frame.maxY > bar.frame.minY - 20 {
            app.swipeUp()
        }
        XCTAssertTrue(water.exists)
        XCTAssertTrue(app.buttons["tile.Towel packed"].exists)
        add.tap()
        XCTAssertTrue(app.buttons["addChecks.chip.Keys packed"].waitForExistence(timeout: 3))
        app.buttons["addChecks.chip.Keys packed"].tap()
        XCTAssertEqual(app.buttons["addChecks.commit"].label, "Add 1 task to Gym")
        app.buttons["addChecks.commit"].tap()
        XCTAssertTrue(app.buttons["tile.Keys packed"].waitForExistence(timeout: 3))
    }

    /// New category starts from the templates; Gym's tasks are renamed and removed before it's created.
    @MainActor
    func testCreatingFromATemplate() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample", "-Open", "newCategory"])
        let gym = app.buttons["templates.gym"]
        XCTAssertTrue(gym.waitForExistence(timeout: 5))
        gym.tap()
        XCTAssertEqual(app.textFields["category.name"].value as? String, "Gym")

        let towel = app.textFields["category.taskName.Towel packed"]
        XCTAssertTrue(towel.waitForExistence(timeout: 3))
        towel.tap()
        // The cursor lands at the end: delete " packed".
        towel.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 7))
        app.buttons["category.keyboardDone"].tap()
        app.buttons["category.removeTask.Headphones charged"].tap()
        app.buttons["category.save"].tap()

        // Gym is the last section, and Today's stacks are lazy: scroll until it's built.
        XCTAssertTrue(app.buttons["tabbar.add"].waitForExistence(timeout: 3))
        let water = app.buttons["tile.Water bottle"]
        for _ in 0..<6 where !water.exists {
            app.swipeUp()
        }
        XCTAssertTrue(water.exists)
        XCTAssertTrue(app.buttons["tile.Towel"].exists)
        XCTAssertFalse(app.buttons["tile.Headphones charged"].exists)
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
        app.buttons["filter.Bin night"].press(forDuration: 1.0)
        app.buttons["Delete category"].firstMatch.tap()
        app.buttons["category.delete.move"].firstMatch.tap()
        XCTAssertFalse(app.buttons["filter.Bin night"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["tile.Bins out"].exists)

        // Delete Travel with its tasks, from Categories in Today's header.
        app.buttons["today.categories"].tap()
        let travel = app.buttons["categories.row.Travel"]
        XCTAssertTrue(travel.waitForExistence(timeout: 3))
        travel.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        app.buttons["category.delete.tasks"].firstMatch.tap()
        XCTAssertFalse(travel.waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["categories.row.Daily"].exists)
    }
}
