import Foundation
import Testing
@testable import Did_I

struct AppLaunchConfigurationTests {
    @Test func realLaunchUsesTheDiskStore() {
        let configuration = AppLaunchConfiguration(arguments: ["Did-I"], environment: [:])
        #expect(!configuration.usesInMemoryStore)
    }

    @Test func uiTestLaunchUsesMemory() {
        let configuration = AppLaunchConfiguration(arguments: ["Did-I", "-UITests"], environment: [:])
        #expect(configuration.isUITesting)
        #expect(configuration.usesInMemoryStore)
    }

    @Test func unitTestHostUsesMemory() {
        let configuration = AppLaunchConfiguration(
            arguments: ["Did-I"],
            environment: ["XCTestConfigurationFilePath": "/tmp/x.xctestconfiguration"]
        )
        #expect(configuration.isUnitTesting)
        #expect(configuration.usesInMemoryStore)
    }

    @Test func testDefaultsStartEmpty() {
        let configuration = AppLaunchConfiguration(arguments: ["-UITests"], environment: [:])
        configuration.makeDefaults().set(true, forKey: "probe")
        #expect(configuration.makeDefaults().object(forKey: "probe") == nil)
    }
}
