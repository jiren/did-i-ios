import SwiftUI

extension CategoryColour {
    var background: Color {
        switch self {
        case .swatch(let swatch): swatch.background
        case .custom:
            components.map { Color(red: $0.red, green: $0.green, blue: $0.blue) } ?? .tileViolet
        }
    }

    /// Text and icons on the colour: white or ink, whichever reads better.
    var foreground: Color {
        switch self {
        case .swatch(let swatch): swatch.foreground
        case .custom: prefersLightForeground ? .white : .onTile
        }
    }

    /// The translucent disc behind an icon on the colour.
    var chip: Color {
        switch self {
        case .swatch(let swatch): swatch.chip
        case .custom: prefersLightForeground ? .white.opacity(0.18) : Color.onTile.opacity(0.10)
        }
    }
}
