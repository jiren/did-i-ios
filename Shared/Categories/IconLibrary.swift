import Foundation

/// The symbols behind New category's "More icons", grouped and searchable. Curated: SF Symbols has no public list.
nonisolated enum IconLibrary {
    struct Entry: Identifiable, Hashable, Sendable {
        let symbol: String
        let title: String
        /// Extra words search matches ("trash" for Bin).
        let keywords: [String]

        var id: String { symbol }
    }

    struct Group: Identifiable, Sendable {
        let id: String
        let title: String
        let entries: [Entry]
    }

    private static func entry(_ symbol: String, _ title: String, _ keywords: String = "") -> Entry {
        Entry(symbol: symbol, title: title, keywords: keywords.split(separator: " ").map(String.init))
    }

    static let groups: [Group] = [
        Group(id: "home", title: String(localized: "Home"), entries: [
            entry("house.fill", String(localized: "Home"), "house"),
            entry("door.left.hand.closed", String(localized: "Door"), "front back"),
            entry("door.garage.closed", String(localized: "Garage")),
            entry("window.vertical.closed", String(localized: "Window")),
            entry("key.fill", String(localized: "Key"), "keys"),
            entry("lock.fill", String(localized: "Lock"), "locked"),
            entry("lightbulb.fill", String(localized: "Light"), "lights lamp"),
            entry("lamp.desk.fill", String(localized: "Lamp")),
            entry("fan.fill", String(localized: "Fan")),
            entry("air.conditioner.horizontal.fill", String(localized: "Air conditioning"), "ac cooling"),
            entry("heater.vertical.fill", String(localized: "Heater"), "heating radiator"),
            entry("spigot.fill", String(localized: "Tap"), "water faucet"),
            entry("shower.fill", String(localized: "Shower")),
            entry("bathtub.fill", String(localized: "Bath")),
            entry("toilet.fill", String(localized: "Toilet")),
            entry("washer.fill", String(localized: "Washing machine"), "laundry"),
            entry("dryer.fill", String(localized: "Dryer"), "laundry"),
            entry("sofa.fill", String(localized: "Sofa"), "living room"),
            entry("bed.double.fill", String(localized: "Bed"), "bedroom"),
            entry("trash.fill", String(localized: "Bin"), "trash rubbish garbage"),
            entry("arrow.3.trianglepath", String(localized: "Recycling"), "recycle"),
            entry("smoke.fill", String(localized: "Smoke alarm"), "fire safety"),
            entry("powerplug.fill", String(localized: "Plug"), "unplugged"),
            entry("poweroutlet.type.b.fill", String(localized: "Socket"), "outlet"),
            entry("flame.fill", String(localized: "Flame"), "fire gas"),
            entry("stove.fill", String(localized: "Stove"), "hob cooker"),
            entry("oven.fill", String(localized: "Oven")),
            entry("microwave.fill", String(localized: "Microwave")),
            entry("refrigerator.fill", String(localized: "Fridge"), "freezer"),
            entry("dishwasher.fill", String(localized: "Dishwasher")),
        ]),
        Group(id: "night", title: String(localized: "Morning & night"), entries: [
            entry("sun.max.fill", String(localized: "Sun"), "morning day"),
            entry("sunrise.fill", String(localized: "Sunrise"), "morning"),
            entry("sunset.fill", String(localized: "Sunset"), "evening"),
            entry("moon.fill", String(localized: "Moon"), "night bedtime"),
            entry("moon.stars.fill", String(localized: "Night"), "bedtime"),
            entry("alarm.fill", String(localized: "Alarm"), "clock wake"),
            entry("zzz", String(localized: "Sleep")),
            entry("clock.fill", String(localized: "Clock"), "time"),
        ]),
        Group(id: "health", title: String(localized: "Health"), entries: [
            entry("pills.fill", String(localized: "Pills"), "medicine medication"),
            entry("cross.case.fill", String(localized: "First aid"), "medical"),
            entry("heart.fill", String(localized: "Heart"), "love"),
            entry("stethoscope", String(localized: "Doctor")),
            entry("syringe.fill", String(localized: "Injection"), "insulin vaccine"),
            entry("bandage.fill", String(localized: "Plaster"), "bandage"),
            entry("brain.head.profile", String(localized: "Mind"), "mental"),
            entry("lungs.fill", String(localized: "Lungs"), "breathing inhaler"),
            entry("drop.fill", String(localized: "Water"), "drink hydrate"),
            entry("eye.fill", String(localized: "Eyes"), "contacts lenses"),
            entry("facemask.fill", String(localized: "Mask")),
            entry("allergens", String(localized: "Allergies"), "pollen"),
            entry("waveform.path.ecg", String(localized: "Heart rate"), "blood pressure"),
            entry("figure.mind.and.body", String(localized: "Meditation"), "calm"),
        ]),
        Group(id: "food", title: String(localized: "Food & shopping"), entries: [
            entry("fork.knife", String(localized: "Meals"), "food eat dinner lunch"),
            entry("cup.and.saucer.fill", String(localized: "Coffee"), "tea"),
            entry("mug.fill", String(localized: "Mug")),
            entry("takeoutbag.and.cup.and.straw.fill", String(localized: "Takeaway")),
            entry("carrot.fill", String(localized: "Vegetables"), "veg"),
            entry("birthday.cake.fill", String(localized: "Cake"), "birthday"),
            entry("wineglass.fill", String(localized: "Wine"), "drinks"),
            entry("waterbottle.fill", String(localized: "Water bottle")),
            entry("frying.pan.fill", String(localized: "Frying pan"), "cooking"),
            entry("cart.fill", String(localized: "Shopping"), "groceries"),
            entry("basket.fill", String(localized: "Basket")),
            entry("bag.fill", String(localized: "Bag")),
        ]),
        Group(id: "pets", title: String(localized: "Pets & plants"), entries: [
            entry("pawprint.fill", String(localized: "Paw"), "pet paw"),
            entry("dog.fill", String(localized: "Dog"), "pet walk"),
            entry("cat.fill", String(localized: "Cat"), "pet"),
            entry("fish.fill", String(localized: "Fish"), "pet tank"),
            entry("bird.fill", String(localized: "Bird"), "pet"),
            entry("hare.fill", String(localized: "Rabbit"), "pet"),
            entry("tortoise.fill", String(localized: "Tortoise"), "pet turtle"),
            entry("leaf.fill", String(localized: "Leaf"), "plants garden"),
            entry("tree.fill", String(localized: "Tree"), "garden"),
            entry("camera.macro", String(localized: "Flower"), "plants"),
            entry("sprinkler.and.droplets.fill", String(localized: "Sprinkler"), "watering garden"),
        ]),
        Group(id: "travel", title: String(localized: "Travel"), entries: [
            entry("suitcase.fill", String(localized: "Suitcase"), "packing trip"),
            entry("suitcase.rolling.fill", String(localized: "Luggage"), "trip"),
            entry("airplane", String(localized: "Plane"), "flight"),
            entry("tram.fill", String(localized: "Train")),
            entry("bus.fill", String(localized: "Bus")),
            entry("ferry.fill", String(localized: "Ferry"), "boat"),
            entry("map.fill", String(localized: "Map")),
            entry("mappin.and.ellipse", String(localized: "Place"), "location"),
            entry("globe", String(localized: "Globe"), "world abroad"),
            entry("person.text.rectangle.fill", String(localized: "ID"), "passport"),
            entry("ticket.fill", String(localized: "Ticket")),
            entry("tent.fill", String(localized: "Tent"), "camping"),
            entry("mountain.2.fill", String(localized: "Mountains"), "hiking"),
            entry("beach.umbrella.fill", String(localized: "Beach"), "holiday"),
            entry("building.2.fill", String(localized: "City"), "office"),
        ]),
        Group(id: "car", title: String(localized: "Car & getting around"), entries: [
            entry("car.fill", String(localized: "Car"), "drive"),
            entry("car.side.fill", String(localized: "Car side")),
            entry("bicycle", String(localized: "Bike"), "cycle"),
            entry("scooter", String(localized: "Scooter")),
            entry("motorcycle", String(localized: "Motorbike")),
            entry("fuelpump.fill", String(localized: "Fuel"), "petrol gas"),
            entry("ev.charger.fill", String(localized: "EV charger"), "electric"),
            entry("parkingsign.circle.fill", String(localized: "Parking")),
            entry("steeringwheel", String(localized: "Steering wheel"), "driving"),
        ]),
        Group(id: "work", title: String(localized: "Work & school"), entries: [
            entry("briefcase.fill", String(localized: "Work"), "office job"),
            entry("laptopcomputer", String(localized: "Laptop")),
            entry("desktopcomputer", String(localized: "Computer")),
            entry("printer.fill", String(localized: "Printer")),
            entry("doc.fill", String(localized: "Document"), "paper"),
            entry("folder.fill", String(localized: "Folder")),
            entry("pencil", String(localized: "Pencil"), "write"),
            entry("book.fill", String(localized: "Book"), "reading"),
            entry("backpack.fill", String(localized: "Backpack"), "school bag"),
            entry("graduationcap.fill", String(localized: "School"), "study"),
            entry("calendar", String(localized: "Calendar")),
            entry("envelope.fill", String(localized: "Mail"), "post letter"),
        ]),
        Group(id: "money", title: String(localized: "Money"), entries: [
            entry("creditcard.fill", String(localized: "Card"), "bills pay"),
            entry("banknote.fill", String(localized: "Cash"), "money"),
            entry("dollarsign.circle.fill", String(localized: "Money")),
            entry("building.columns.fill", String(localized: "Bank")),
            entry("chart.line.uptrend.xyaxis", String(localized: "Savings"), "investments"),
            entry("doc.text.fill", String(localized: "Bill"), "invoice"),
            entry("gift.fill", String(localized: "Gift"), "present"),
            entry("giftcard.fill", String(localized: "Gift card")),
        ]),
        Group(id: "sport", title: String(localized: "Sport & fitness"), entries: [
            entry("figure.run", String(localized: "Run"), "running gym"),
            entry("figure.walk", String(localized: "Walk"), "steps"),
            entry("figure.strengthtraining.traditional", String(localized: "Weights"), "gym"),
            entry("dumbbell.fill", String(localized: "Dumbbell"), "gym"),
            entry("figure.yoga", String(localized: "Yoga")),
            entry("figure.pool.swim", String(localized: "Swim"), "pool"),
            entry("figure.hiking", String(localized: "Hike")),
            entry("soccerball", String(localized: "Football"), "soccer"),
            entry("basketball.fill", String(localized: "Basketball")),
            entry("tennis.racket", String(localized: "Tennis")),
            entry("trophy.fill", String(localized: "Trophy")),
            entry("stopwatch.fill", String(localized: "Stopwatch"), "timer"),
        ]),
        Group(id: "tech", title: String(localized: "Gadgets"), entries: [
            entry("iphone", String(localized: "Phone"), "mobile"),
            entry("ipad", String(localized: "Tablet")),
            entry("applewatch", String(localized: "Watch")),
            entry("headphones", String(localized: "Headphones")),
            entry("battery.100percent", String(localized: "Battery"), "charge"),
            entry("bolt.fill", String(localized: "Charge"), "charger power"),
            entry("wifi", String(localized: "Wi-Fi"), "internet router"),
            entry("tv.fill", String(localized: "TV")),
            entry("gamecontroller.fill", String(localized: "Games")),
            entry("camera.fill", String(localized: "Camera")),
            entry("speaker.wave.2.fill", String(localized: "Speaker")),
        ]),
        Group(id: "personal", title: String(localized: "People & things"), entries: [
            entry("person.fill", String(localized: "Person")),
            entry("person.2.fill", String(localized: "People"), "family friends"),
            entry("figure.and.child.holdinghands", String(localized: "Family"), "kids children"),
            entry("stroller.fill", String(localized: "Pram"), "baby stroller"),
            entry("teddybear.fill", String(localized: "Teddy"), "baby toys"),
            entry("tshirt.fill", String(localized: "Clothes"), "laundry"),
            entry("hanger", String(localized: "Hanger"), "wardrobe"),
            entry("comb.fill", String(localized: "Comb"), "hair beauty"),
            entry("eyeglasses", String(localized: "Glasses")),
            entry("umbrella.fill", String(localized: "Umbrella"), "rain"),
            entry("scissors", String(localized: "Scissors")),
            entry("hammer.fill", String(localized: "Hammer"), "diy"),
            entry("wrench.and.screwdriver.fill", String(localized: "Tools"), "repair"),
            entry("paintbrush.fill", String(localized: "Paint")),
            entry("music.note", String(localized: "Music")),
            entry("bell.fill", String(localized: "Bell"), "reminder"),
            entry("star.fill", String(localized: "Star"), "favourite"),
            entry("flag.fill", String(localized: "Flag")),
            entry("checkmark.seal.fill", String(localized: "Done"), "check"),
            entry("sparkles", String(localized: "Sparkles"), "clean tidy"),
        ]),
    ]

    static let allEntries: [Entry] = groups.flatMap(\.entries)

    /// Entries whose title, symbol or keywords contain every word of `text`, ignoring case; all of them when empty.
    static func search(_ text: String) -> [Entry] {
        let words = text.lowercased().split(separator: " ").map(String.init)
        guard !words.isEmpty else { return allEntries }
        return allEntries.filter { entry in
            let haystack = ([entry.title, entry.symbol] + entry.keywords).joined(separator: " ").lowercased()
            return words.allSatisfy { haystack.contains($0) }
        }
    }

    /// The library's name for a symbol, else a readable form of the symbol ("pawprint").
    static func title(for symbol: String) -> String {
        allEntries.first { $0.symbol == symbol }?.title
            ?? symbol.replacingOccurrences(of: ".fill", with: "").replacingOccurrences(of: ".", with: " ")
    }
}
