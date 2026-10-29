import SwiftUI

/// The design's large capsule buttons ("Log it again", "Add 2 checks", "Done").
struct PillButtonStyle: ButtonStyle {
    enum Variant {
        /// Ink.
        case ink
        /// Violet.
        case brand
        /// White with ink text, on a coloured screen.
        case light
        /// A white outline on a coloured screen.
        case outline
    }

    var variant: Variant = .ink
    var height: CGFloat = 60
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.didButton)
            .foregroundStyle(foreground)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(background, in: .capsule)
            .overlay {
                if variant == .outline {
                    Capsule().strokeBorder(.white.opacity(0.6), lineWidth: 2)
                }
            }
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }

    private var foreground: Color {
        guard isEnabled else { return .muted }
        switch variant {
        case .ink: return .onChrome
        case .brand, .outline: return .white
        case .light: return .onTile
        }
    }

    private var background: Color {
        guard isEnabled else { return .sand }
        switch variant {
        case .ink: return .chrome
        case .brand: return .tileViolet
        case .light: return .white
        case .outline: return .clear
        }
    }
}
