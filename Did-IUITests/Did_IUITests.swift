import XCTest

final class Did_IUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchesToTheRootView() throws {
        let app = XCUIApplication.launched()
        XCTAssertTrue(app.descendants(matching: .any)["root"].waitForExistence(timeout: 5))
    }
}
