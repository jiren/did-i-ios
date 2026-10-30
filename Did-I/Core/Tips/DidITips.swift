import SwiftUI
import TipKit

/// "Hold a tile to change it", shown once there are checks on Today.
struct EditTileTip: Tip {
    var title: Text { Text("Hold a tile to change it") }
    var message: Text? { Text("Rename it, pick another icon, move it or remove it. Drag to reorder.") }
    var image: Image? { Image(systemName: "hand.tap") }
}

/// "Group your checks", on the New category chip once there are three or more tasks.
struct NewCategoryTip: Tip {
    @Parameter static var taskCount: Int = 0

    var title: Text { Text("Group your checks") }
    var message: Text? { Text("A category can repeat weekly, monthly or once — like bin night or a trip.") }
    var image: Image? { Image(systemName: "square.grid.2x2") }
    var rules: [Rule] { [#Rule(Self.$taskCount) { $0 >= 3 }] }
}

enum DidITips {
    static func configure(forTesting: Bool) {
        if forTesting { Tips.hideAllTipsForTesting() }
        try? Tips.configure([.displayFrequency(.immediate)])
    }
}
