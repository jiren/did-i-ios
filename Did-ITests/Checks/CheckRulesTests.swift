import Foundation
import Testing
@testable import Did_I

struct CheckRulesTests {
    @Test(arguments: [
        ("Front door locked", CheckKind.door),
        ("Car locked", .car),
        ("Pill taken", .pill),
        ("Stove off", .stove),
        ("Iron unplugged", .plug),
        ("Windows closed", .window),
        ("Tap off", .tap),
        ("Lights off", .light),
        ("Garage shut", .garage),
        ("Cat fed", .other),
    ])
    func kindFromName(name: String, kind: CheckKind) {
        #expect(CheckKind.suggested(forName: name) == kind)
    }

    @Test(arguments: [
        ("Front door locked", "Locked"),
        ("Pill taken", "Taken"),
        ("Heater off", "Off"),
        ("Cat fed", "Fed"),
        ("Water the plants", "Logged"),
    ])
    func state(name: String, state: String) {
        #expect(CheckName.state(of: name) == state)
    }

    @Test func namesAreTrimmedAndCapped() {
        #expect(CheckName.cleaned("  Cat fed \n") == "Cat fed")
        #expect(CheckName.cleaned("   ") == nil)
        #expect(CheckName.cleaned(String(repeating: "a", count: 80))?.count == CheckName.maximumLength)
    }

    @Test func suggestionsSkipExistingChecks() {
        let available = CheckSuggestions.available(excluding: ["front door LOCKED ", "Pill taken"])
        #expect(available.first == "Stove off")
        #expect(!available.contains("Pill taken"))
    }

    @Test func swatchesCycle() {
        #expect(TileSwatch.at(position: 0) == .violet)
        #expect(TileSwatch.at(position: 5) == .pink)
        #expect(TileSwatch.at(position: 6) == .violet)
    }

    @Test func sourcesLabelPhotos() {
        #expect(LogSource.actionButton.label(hasPhoto: true) == "Action Button · photo")
        #expect(LogSource.app.label(hasPhoto: false) == "In the app")
    }
}
