import SwiftUI
import TipKit

/// "Hold a tile to change it", shown once there are checks on Today.
struct EditTileTip: Tip {
    var title: Text { Text("Hold a tile to change it") }
    var message: Text? { Text("Rename it, pick another icon, move it or remove it. Drag to reorder.") }
    var image: Image? { Image(systemName: "hand.tap") }
}

enum DidITips {
    static func configure(forTesting: Bool) {
        if forTesting { Tips.hideAllTipsForTesting() }
        try? Tips.configure([.displayFrequency(.immediate)])
    }
}
