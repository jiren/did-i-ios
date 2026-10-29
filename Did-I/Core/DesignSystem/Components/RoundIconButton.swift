import SwiftUI

/// A 44 pt circular icon button.
struct RoundIconButton: View {
    enum Style {
        /// Ink disc (Today's settings, ActionButton's back).
        case chrome
        /// Translucent white on a coloured header (Detail).
        case onColor
        /// Sand disc (the sheet's close button).
        case sand
    }

    let systemName: String
    let label: String
    var style: Style = .chrome
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(foreground)
                .frame(width: 44, height: 44)
                .background(background, in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var foreground: Color {
        switch style {
        case .chrome: .onChrome
        case .onColor: .white
        case .sand: .ink
        }
    }

    private var background: Color {
        switch style {
        case .chrome: .chrome
        case .onColor: .white.opacity(0.18)
        case .sand: .sand
        }
    }
}
