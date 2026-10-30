import XCTest

final class ChecksUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddingSuggestionsAndACustomCheck() throws {
        let app = XCUIApplication.launched()
        app.buttons["today.empty.add"].tap()
        app.buttons["addChecks.chip.Front door locked"].tap()
        app.buttons["addChecks.chip.Stove off"].tap()
        let field = app.textFields["addChecks.custom"]
        field.tap()
        field.typeText("Cat fed")
        app.buttons["addChecks.addCustom"].tap()
        XCTAssertEqual(app.buttons["addChecks.commit"].label, "Add 3 checks")
        app.buttons["addChecks.commit"].tap()

        XCTAssertTrue(app.buttons["tile.Front door locked"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["tile.Stove off"].exists)
        XCTAssertTrue(app.buttons["tile.Cat fed"].exists)
    }

    @MainActor
    func testRenamingAndRemovingACheck() throws {
        let app = XCUIApplication.launched(arguments: ["-SeedSample"])
        let tile = app.buttons["tile.Stove off"]
        XCTAssertTrue(tile.waitForExistence(timeout: 5))

        tile.press(forDuration: 1.0)
        app.buttons["Rename"].tap()
        // SwiftUI drops identifiers on an alert's text field; it's the alert's only one.
        let field = app.alerts.firstMatch.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.clearAndType("Oven off")
        app.buttons["rename.save"].firstMatch.tap()
        XCTAssertTrue(app.buttons["tile.Oven off"].waitForExistence(timeout: 2))

        app.buttons["tile.Oven off"].press(forDuration: 1.0)
        app.buttons["Remove"].tap()
        app.buttons["remove.confirm"].firstMatch.tap()
        XCTAssertFalse(app.buttons["tile.Oven off"].waitForExistence(timeout: 1))
    }
}

extension XCUIElement {
    func clearAndType(_ text: String) {
        tap()
        if let current = value as? String, !current.isEmpty {
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        typeText(text)
    }
}
