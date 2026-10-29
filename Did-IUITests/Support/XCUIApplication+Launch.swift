import XCTest

extension XCUIApplication {
    /// Launches with an in-memory store and fresh settings, plus any extra arguments.
    @MainActor
    static func launched(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests"] + arguments
        app.launch()
        return app
    }
}
