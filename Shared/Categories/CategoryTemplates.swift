import Foundation

/// A ready-made category to start New category from (`Plan.md`, Phase 20). Everything it fills stays editable.
nonisolated struct CategoryTemplate: Identifiable, Hashable, Sendable {
    /// How often it repeats; the day comes from when it's used (today's weekday or date, or tomorrow for a trip).
    enum Repeat: Hashable, Sendable {
        case daily, weekly, monthly, onceTomorrow
    }

    let id: String
    let name: String
    let icon: CategoryIcon
    let colour: CategoryColour
    let repeats: Repeat
    let tasks: [String]
    /// Minutes after midnight, or nil for no reminder.
    let reminderMinutes: Int?

    /// The rule for a category made from this template on `today`.
    func rule(today: CalendarDay, calendar: Calendar) -> RepeatRule {
        switch repeats {
        case .daily: .daily
        case .weekly: .weekly(weekday: today.weekday(in: calendar))
        case .monthly: .monthly(day: today.day)
        case .onceTomorrow: .once(today.adding(days: 1, calendar: calendar))
        }
    }
}

nonisolated enum CategoryTemplates {
    static let all: [CategoryTemplate] = [
        CategoryTemplate(
            id: "leavingHome", name: String(localized: "Leaving home"), icon: .home, colour: .coral, repeats: .daily,
            tasks: [
                String(localized: "Front door locked"), String(localized: "Stove off"), String(localized: "Iron unplugged"),
                String(localized: "Lights off"), String(localized: "Windows closed"),
            ],
            reminderMinutes: nil
        ),
        CategoryTemplate(
            id: "bedtime", name: String(localized: "Bedtime"), icon: CategoryIcon(symbol: "moon.fill"), colour: .violet,
            repeats: .daily,
            tasks: [
                String(localized: "Back door locked"), String(localized: "Stove off"), String(localized: "Phone charging"),
                String(localized: "Alarm set"),
            ],
            reminderMinutes: 22 * 60
        ),
        CategoryTemplate(
            id: "morning", name: String(localized: "Morning"), icon: .sun, colour: .sun, repeats: .daily,
            tasks: [String(localized: "Pill taken"), String(localized: "Coffee machine off"), String(localized: "Hair tool off")],
            reminderMinutes: nil
        ),
        CategoryTemplate(
            id: "medication", name: String(localized: "Medication"), icon: .pill, colour: .violet, repeats: .daily,
            tasks: [String(localized: "Morning pill"), String(localized: "Evening pill")],
            reminderMinutes: 21 * 60
        ),
        CategoryTemplate(
            id: "binNight", name: String(localized: "Bin night"), icon: .bin, colour: .mint, repeats: .weekly,
            tasks: [String(localized: "Bins out"), String(localized: "Recycling out")],
            reminderMinutes: 20 * 60
        ),
        CategoryTemplate(
            id: "trip", name: String(localized: "Trip"), icon: .suitcase, colour: .sky, repeats: .onceTomorrow,
            tasks: [
                String(localized: "Passport packed"), String(localized: "Charger packed"), String(localized: "Windows closed"),
                String(localized: "Water main off"), String(localized: "Heating off"),
            ],
            reminderMinutes: 20 * 60
        ),
        CategoryTemplate(
            id: "gym", name: String(localized: "Gym"), icon: CategoryIcon(symbol: "figure.run"), colour: .pink, repeats: .weekly,
            tasks: [String(localized: "Water bottle"), String(localized: "Towel packed"), String(localized: "Headphones charged")],
            reminderMinutes: nil
        ),
        CategoryTemplate(
            id: "pets", name: String(localized: "Pets"), icon: CategoryIcon(symbol: "pawprint.fill"), colour: .coral,
            repeats: .daily,
            tasks: [String(localized: "Dog fed"), String(localized: "Water bowl filled"), String(localized: "Dog walked")],
            reminderMinutes: nil
        ),
        CategoryTemplate(
            id: "plants", name: String(localized: "Plants"), icon: CategoryIcon(symbol: "leaf.fill"), colour: .mint,
            repeats: .weekly,
            tasks: [String(localized: "Plants watered")],
            reminderMinutes: nil
        ),
        CategoryTemplate(
            id: "car", name: String(localized: "Car"), icon: .car, colour: .sky, repeats: .daily,
            tasks: [String(localized: "Car locked"), String(localized: "Headlights off"), String(localized: "Windows up")],
            reminderMinutes: nil
        ),
        CategoryTemplate(
            id: "homeSafety", name: String(localized: "Home safety"), icon: .flame, colour: .coral, repeats: .monthly,
            tasks: [
                String(localized: "Smoke alarm tested"), String(localized: "Extinguisher checked"),
                String(localized: "CO alarm tested"),
            ],
            reminderMinutes: nil
        ),
        CategoryTemplate(
            id: "bills", name: String(localized: "Bills"), icon: CategoryIcon(symbol: "creditcard.fill"), colour: .sun,
            repeats: .monthly,
            tasks: [String(localized: "Rent paid"), String(localized: "Card bill paid")],
            reminderMinutes: nil
        ),
    ]
}
