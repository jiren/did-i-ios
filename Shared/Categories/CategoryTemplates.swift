import Foundation

/// A ready-made category to start New category from (`Plan.md`, phases 20 and 23). Everything it fills stays
/// editable.
nonisolated struct CategoryTemplate: Identifiable, Hashable, Sendable {
    /// How often it repeats; the day comes from when it's used (today's weekday or date, or tomorrow for a trip).
    enum Repeat: Hashable, Sendable {
        case daily
        /// On today's weekday.
        case weekly
        /// On these weekdays (1 = Sunday).
        case weeklyOn(Set<Int>)
        /// Monday to Friday.
        case weekdays
        /// Every other week from today's weekday.
        case everyTwoWeeks
        /// On today's day of the month.
        case monthly
        /// On today's date each year.
        case yearly
        case onceTomorrow
    }

    let id: String
    let name: String
    let icon: CategoryIcon
    let colour: CategoryColour
    let repeats: Repeat
    let tasks: [String]
    /// Minutes after midnight, or nil for no reminder.
    let reminderMinutes: Int?
    /// Its tasks nudge when leaving home (once a home is set).
    var nudgesOnLeavingHome = false

    /// The rule for a category made from this template on `today`.
    func rule(today: CalendarDay, calendar: Calendar) -> RepeatRule {
        switch repeats {
        case .daily: .daily
        case .weekly: .weekly(weekday: today.weekday(in: calendar))
        case .weeklyOn(let days): .weekly(weekdays: days)
        case .weekdays: .weekly(weekdays: RepeatRule.workingDays)
        case .everyTwoWeeks: .everyTwoWeeks(weekday: today.weekday(in: calendar), startingOnOrAfter: today, calendar: calendar)
        case .monthly: .monthly(day: today.day)
        case .yearly: .yearly(month: today.month, day: today.day)
        case .onceTomorrow: .once(today.adding(days: 1, calendar: calendar))
        }
    }
}

/// The gallery's sections.
nonisolated struct CategoryTemplateGroup: Identifiable, Sendable {
    let id: String
    let title: String
    let templates: [CategoryTemplate]
}

nonisolated enum CategoryTemplates {
    private static func symbol(_ name: String) -> CategoryIcon { CategoryIcon(symbol: name) }

    static let groups: [CategoryTemplateGroup] = [
        CategoryTemplateGroup(id: "home", title: String(localized: "Home & safety"), templates: [
            CategoryTemplate(
                id: "leavingHome", name: String(localized: "Leaving home"), icon: .home, colour: .coral, repeats: .daily,
                tasks: [
                    String(localized: "Front door locked"), String(localized: "Back door locked"), String(localized: "Stove off"),
                    String(localized: "Iron unplugged"), String(localized: "Windows closed"), String(localized: "Lights off"),
                ],
                reminderMinutes: nil, nudgesOnLeavingHome: true
            ),
            CategoryTemplate(
                id: "bedtime", name: String(localized: "Bedtime"), icon: symbol("moon.fill"), colour: .violet, repeats: .daily,
                tasks: [
                    String(localized: "Front door locked"), String(localized: "Back door locked"), String(localized: "Stove off"),
                    String(localized: "Candles out"), String(localized: "Phone charging"), String(localized: "Alarm set"),
                ],
                reminderMinutes: 22 * 60
            ),
            CategoryTemplate(
                id: "kitchen", name: String(localized: "Kitchen"), icon: symbol("stove.fill"), colour: .coral, repeats: .daily,
                tasks: [String(localized: "Oven off"), String(localized: "Hob off"), String(localized: "Kettle off"), String(localized: "Fridge shut")],
                reminderMinutes: 21 * 60
            ),
            CategoryTemplate(
                id: "water", name: String(localized: "Water"), icon: symbol("drop.fill"), colour: .sky, repeats: .daily,
                tasks: [String(localized: "Taps off"), String(localized: "Bath tap off"), String(localized: "Hose off")],
                reminderMinutes: nil
            ),
            CategoryTemplate(
                id: "laundry", name: String(localized: "Laundry"), icon: symbol("washer.fill"), colour: .sky, repeats: .weekly,
                tasks: [String(localized: "Washer emptied"), String(localized: "Dryer filter cleared"), String(localized: "Iron unplugged")],
                reminderMinutes: nil
            ),
            CategoryTemplate(
                id: "binNight", name: String(localized: "Bin night"), icon: .bin, colour: .mint, repeats: .weekly,
                tasks: [
                    String(localized: "Bins out"), String(localized: "Recycling out"), String(localized: "Food caddy out"),
                    String(localized: "Garden waste out"),
                ],
                reminderMinutes: 20 * 60
            ),
            CategoryTemplate(
                id: "recycling", name: String(localized: "Recycling"), icon: symbol("arrow.3.trianglepath"), colour: .mint,
                repeats: .everyTwoWeeks,
                tasks: [String(localized: "Recycling out"), String(localized: "Glass out")],
                reminderMinutes: 20 * 60
            ),
            CategoryTemplate(
                id: "homeSafety", name: String(localized: "Home safety"), icon: .flame, colour: .coral, repeats: .monthly,
                tasks: [String(localized: "Smoke alarm tested"), String(localized: "CO alarm tested"), String(localized: "Extinguisher checked")],
                reminderMinutes: nil
            ),
            CategoryTemplate(
                id: "yearlyHome", name: String(localized: "Yearly home"), icon: symbol("wrench.and.screwdriver.fill"), colour: .sun,
                repeats: .yearly,
                tasks: [String(localized: "Boiler serviced"), String(localized: "Smoke alarm batteries changed"), String(localized: "Chimney swept")],
                reminderMinutes: nil
            ),
        ]),
        CategoryTemplateGroup(id: "out", title: String(localized: "Out & about"), templates: [
            CategoryTemplate(
                id: "outTheDoor", name: String(localized: "Out the door"), icon: .key, colour: .sun, repeats: .daily,
                tasks: [String(localized: "Keys with me"), String(localized: "Phone with me"), String(localized: "Wallet with me")],
                reminderMinutes: nil, nudgesOnLeavingHome: true
            ),
            CategoryTemplate(
                id: "leavingWork", name: String(localized: "Leaving work"), icon: symbol("briefcase.fill"), colour: .sky,
                repeats: .weekdays,
                tasks: [String(localized: "Laptop locked"), String(localized: "Desk lamp off"), String(localized: "Locker locked")],
                reminderMinutes: 17 * 60 + 30
            ),
            CategoryTemplate(
                id: "car", name: String(localized: "Car"), icon: .car, colour: .sky, repeats: .daily,
                tasks: [
                    String(localized: "Car locked"), String(localized: "Handbrake on"), String(localized: "Windows up"),
                    String(localized: "Back seat checked"),
                ],
                reminderMinutes: nil
            ),
            CategoryTemplate(
                id: "trip", name: String(localized: "Trip"), icon: .suitcase, colour: .sky, repeats: .onceTomorrow,
                tasks: [
                    String(localized: "Passport packed"), String(localized: "Charger packed"), String(localized: "Fridge emptied"),
                    String(localized: "Plants watered"), String(localized: "Windows closed"), String(localized: "Heating off"),
                    String(localized: "Water main off"), String(localized: "Doors locked"),
                ],
                reminderMinutes: 20 * 60
            ),
            CategoryTemplate(
                id: "gym", name: String(localized: "Gym"), icon: symbol("figure.run"), colour: .pink, repeats: .weeklyOn([2, 4, 6]),
                tasks: [
                    String(localized: "Gym bag packed"), String(localized: "Shoes packed"), String(localized: "Water bottle"),
                    String(localized: "Locker locked"),
                ],
                reminderMinutes: nil
            ),
            CategoryTemplate(
                id: "hairBeauty", name: String(localized: "Hair & beauty"), icon: symbol("comb.fill"), colour: .pink, repeats: .daily,
                tasks: [String(localized: "Straighteners off"), String(localized: "Curling iron off"), String(localized: "Hairdryer unplugged")],
                reminderMinutes: nil
            ),
        ]),
        CategoryTemplateGroup(id: "health", title: String(localized: "Health"), templates: [
            CategoryTemplate(
                id: "morningMeds", name: String(localized: "Morning meds"), icon: .pill, colour: .violet, repeats: .daily,
                tasks: [String(localized: "Morning meds taken"), String(localized: "Vitamins taken")],
                reminderMinutes: 9 * 60
            ),
            CategoryTemplate(
                id: "eveningMeds", name: String(localized: "Evening meds"), icon: .pill, colour: .sky, repeats: .daily,
                tasks: [String(localized: "Evening meds taken")],
                reminderMinutes: 21 * 60
            ),
            CategoryTemplate(
                id: "diabetes", name: String(localized: "Diabetes"), icon: symbol("syringe.fill"), colour: .coral, repeats: .daily,
                tasks: [String(localized: "Insulin taken"), String(localized: "Glucose checked")],
                reminderMinutes: 8 * 60
            ),
            CategoryTemplate(
                id: "contacts", name: String(localized: "Contact lenses"), icon: symbol("eye.fill"), colour: .sky, repeats: .daily,
                tasks: [String(localized: "Lenses out"), String(localized: "Case closed")],
                reminderMinutes: 22 * 60
            ),
            CategoryTemplate(
                id: "pharmacy", name: String(localized: "Pharmacy"), icon: symbol("cross.case.fill"), colour: .mint, repeats: .monthly,
                tasks: [String(localized: "Prescription refilled")],
                reminderMinutes: nil
            ),
        ]),
        CategoryTemplateGroup(id: "family", title: String(localized: "Family & pets"), templates: [
            CategoryTemplate(
                id: "schoolRun", name: String(localized: "School run"), icon: symbol("backpack.fill"), colour: .sun, repeats: .weekdays,
                tasks: [String(localized: "School bag packed"), String(localized: "Lunch packed"), String(localized: "Back seat checked")],
                reminderMinutes: 7 * 60 + 30
            ),
            CategoryTemplate(
                id: "pets", name: String(localized: "Pets"), icon: symbol("pawprint.fill"), colour: .coral, repeats: .daily,
                tasks: [
                    String(localized: "Fed in the morning"), String(localized: "Fed in the evening"), String(localized: "Fresh water"),
                    String(localized: "Meds given"),
                ],
                reminderMinutes: nil
            ),
            CategoryTemplate(
                id: "plants", name: String(localized: "Plants"), icon: symbol("leaf.fill"), colour: .mint, repeats: .weekly,
                tasks: [String(localized: "Indoor plants watered"), String(localized: "Garden watered")],
                reminderMinutes: nil
            ),
            CategoryTemplate(
                id: "caring", name: String(localized: "Caring for someone"), icon: .heart, colour: .pink, repeats: .daily,
                tasks: [String(localized: "Meds given"), String(localized: "Checked in"), String(localized: "Door locked behind me")],
                reminderMinutes: 9 * 60
            ),
        ]),
        CategoryTemplateGroup(id: "money", title: String(localized: "Money & admin"), templates: [
            CategoryTemplate(
                id: "bills", name: String(localized: "Bills"), icon: symbol("creditcard.fill"), colour: .sun, repeats: .monthly,
                tasks: [
                    String(localized: "Rent paid"), String(localized: "Utilities paid"), String(localized: "Phone bill paid"),
                    String(localized: "Card bill paid"),
                ],
                reminderMinutes: nil
            ),
            CategoryTemplate(
                id: "carAdmin", name: String(localized: "Car admin"), icon: symbol("car.side.fill"), colour: .sky, repeats: .yearly,
                tasks: [String(localized: "Insurance renewed"), String(localized: "Car serviced"), String(localized: "Car tax paid")],
                reminderMinutes: nil
            ),
        ]),
    ]

    /// Every template, in the gallery's order.
    static let all: [CategoryTemplate] = groups.flatMap(\.templates)
}
