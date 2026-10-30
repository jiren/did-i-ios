import Foundation
import Testing
import UIKit
@testable import Did_I

struct CategoryColourTests {
    @Test func swatchKeysAndHexRoundTrip() {
        #expect(CategoryColour(key: "mint") == .mint)
        #expect(CategoryColour(key: "#5bc0ff") == .custom(hex: "#5BC0FF"))
        #expect(CategoryColour.custom(red: 1, green: 0.5, blue: 0).key == "#FF8000")
        #expect(CategoryColour(key: CategoryColour.custom(red: 0.2, green: 0.4, blue: 0.6).key) == .custom(red: 0.2, green: 0.4, blue: 0.6))
    }

    @Test(arguments: ["", "teal", "#12345", "#GGGGGG", "123456"])
    func badKeysAreRejected(key: String) {
        #expect(CategoryColour(key: key) == nil)
    }

    @Test func outOfRangeComponentsAreClamped() {
        #expect(CategoryColour.custom(red: 1.2, green: -0.1, blue: 0.5).key == "#FF0080")
    }

    @Test func theForegroundIsWhichReadsBetter() {
        #expect(CategoryColour.violet.prefersLightForeground)
        #expect(!CategoryColour.sun.prefersLightForeground)
        #expect(!CategoryColour.custom(hex: "#FFFF00").prefersLightForeground)
        #expect(CategoryColour.custom(hex: "#1A237E").prefersLightForeground)
        #expect(!CategoryColour.custom(hex: "#F0F0F0").prefersLightForeground)
    }
}

struct CategoryIconTests {
    @Test func drawnIconsAndLibrarySymbolsRoundTrip() {
        #expect(CategoryIcon(rawValue: "bin") == .bin)
        #expect(CategoryIcon(rawValue: "sf:pawprint.fill")?.symbolName == "pawprint.fill")
        #expect(CategoryIcon(symbol: "pawprint.fill").rawValue == "sf:pawprint.fill")
        // A drawn icon's symbol is that icon.
        #expect(CategoryIcon(symbol: "trash.fill") == .bin)
        #expect(CategoryIcon(rawValue: "sf:") == nil)
        #expect(CategoryIcon(rawValue: "nope") == nil)
        #expect(CategoryIcon.featured.count == 12)
    }

    @Test func titlesComeFromTheLibrary() {
        #expect(CategoryIcon.bin.title == "Bin")
        #expect(CategoryIcon(symbol: "pawprint.fill").title == "Paw")
    }

    @Test func everyLibrarySymbolExistsOnce() {
        let symbols = IconLibrary.allEntries.map(\.symbol)
        #expect(Set(symbols).count == symbols.count)
        #expect(symbols.count >= 150)
        for symbol in symbols {
            #expect(UIImage(systemName: symbol) != nil, "\(symbol)")
        }
    }

    @Test func searchMatchesTitlesAndKeywords() {
        #expect(IconLibrary.search("paw").map(\.symbol).contains("pawprint.fill"))
        #expect(IconLibrary.search("TRASH").map(\.symbol) == ["trash.fill"])
        #expect(IconLibrary.search("").count == IconLibrary.allEntries.count)
        #expect(IconLibrary.search("zzzz qqq").isEmpty)
    }
}

struct CategoryTemplateTests {
    private let calendar = TestTime.calendar()
    // Thursday, Oct 29, 2026.
    private let today = CalendarDay(year: 2026, month: 10, day: 29)

    @Test func templatesAreUniqueAndComplete() {
        let templates = CategoryTemplates.all
        #expect(Set(templates.map(\.id)).count == templates.count)
        #expect(Set(templates.map { $0.name.lowercased() }).count == templates.count)
        for template in templates {
            #expect(!template.tasks.isEmpty, "\(template.id)")
            #expect(UIImage(systemName: template.icon.symbolName) != nil, "\(template.id)")
            #expect(Set(template.tasks.map { $0.lowercased() }).count == template.tasks.count, "\(template.id)")
        }
    }

    @Test func rulesStartFromToday() {
        func rule(_ id: String) -> RepeatRule? {
            CategoryTemplates.all.first { $0.id == id }?.rule(today: today, calendar: calendar)
        }
        #expect(rule("leavingHome") == .daily)
        #expect(rule("binNight") == .weekly(weekday: 5))
        #expect(rule("homeSafety") == .monthly(day: 29))
        #expect(rule("trip") == .once(CalendarDay(year: 2026, month: 10, day: 30)))
        #expect(rule("leavingWork") == .weekly(weekdays: RepeatRule.workingDays))
        #expect(rule("gym") == .weekly(weekdays: [2, 4, 6]))
        #expect(rule("yearlyHome") == .yearly(month: 10, day: 29))
        // Every other Thursday, from today.
        #expect(rule("recycling") == .everyTwoWeeks(weekday: 5, anchor: today))
    }

    @Test func templatesAreGroupedAndTheLeavingOnesNudge() {
        #expect(CategoryTemplates.groups.map(\.title) == ["Home & safety", "Out & about", "Health", "Family & pets", "Money & admin"])
        #expect(CategoryTemplates.all.count >= 25)
        let nudging = CategoryTemplates.all.filter(\.nudgesOnLeavingHome).map(\.id)
        #expect(nudging == ["leavingHome", "outTheDoor"])
    }
}

struct CheckLabelsTests {
    @Test func aSharedNameNamesItsCategory() {
        let bedtime = CategoryRecord(id: UUID(), name: "Bedtime", icon: .home, colour: .violet, rule: .daily, order: 1, isDefault: false)
        let daily = CategoryRecord(id: CategoryDefaults.dailyID, name: "Daily", icon: .sun, colour: .violet, rule: .daily, order: 0, isDefault: true)
        let checks = [
            CheckRecord(id: UUID(), name: "Stove off", kind: .stove, order: 0, categoryID: daily.id, nudgesOnLeavingHome: false),
            CheckRecord(id: UUID(), name: "stove off", kind: .stove, order: 1, categoryID: bedtime.id, nudgesOnLeavingHome: false),
            CheckRecord(id: UUID(), name: "Pill taken", kind: .pill, order: 2, categoryID: daily.id, nudgesOnLeavingHome: false),
        ]
        let titles = CheckLabels.titles(for: checks, categories: [daily, bedtime])
        #expect(titles[checks[0].id] == "Stove off · Daily")
        #expect(titles[checks[1].id] == "stove off · Bedtime")
        #expect(titles[checks[2].id] == "Pill taken")
    }
}
