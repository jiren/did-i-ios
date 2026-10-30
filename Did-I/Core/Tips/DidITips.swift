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

/// Hides a tip a few seconds after it first shows, for good: tips are one-time hints. Not while VoiceOver is
/// running, so it can't vanish before it's read; the × or the tip's action still dismiss it.
struct AutoDismissingTip<T: Tip>: ViewModifier {
    let tip: T
    let delay: Duration

    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverOn

    func body(content: Content) -> some View {
        content.task(id: isVoiceOverOn) {
            guard !isVoiceOverOn else { return }
            // Wait until the tip is actually showing, so a tip whose rules haven't passed isn't used up.
            for await shouldDisplay in tip.shouldDisplayUpdates where shouldDisplay {
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                tip.invalidate(reason: .displayCountExceeded)
                return
            }
        }
    }
}

extension View {
    func autoDismissing<T: Tip>(_ tip: T, after delay: Duration = .seconds(5)) -> some View {
        modifier(AutoDismissingTip(tip: tip, delay: delay))
    }
}

enum DidITips {
    static func configure(forTesting: Bool) {
        if forTesting { Tips.hideAllTipsForTesting() }
        try? Tips.configure([.displayFrequency(.immediate)])
    }
}
