import SwiftUI

/// The 44 pt disc with the check's symbol.
struct TileIcon: View {
    let kind: CheckKind
    let swatch: TileSwatch
    let isDone: Bool

    var body: some View {
        Image(systemName: kind.symbolName)
            .font(.system(size: 19, weight: .semibold))
            .foregroundStyle(swatch.foreground)
            .frame(width: 44, height: 44)
            .background(isDone ? swatch.chip : swatch.background, in: .circle)
            .accessibilityHidden(true)
    }
}
