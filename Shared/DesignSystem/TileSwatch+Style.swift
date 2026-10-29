import SwiftUI

extension TileSwatch {
    var background: Color {
        switch self {
        case .violet: .tileViolet
        case .sun: .tileSun
        case .coral: .tileCoral
        case .mint: .tileMint
        case .sky: .tileSky
        case .pink: .tilePink
        }
    }

    /// Text and icons on the tile.
    var foreground: Color {
        self == .violet ? .white : .onTile
    }

    /// The tile's secondary line.
    var secondary: Color {
        switch self {
        case .violet: .tileVioletSub
        case .sun: .tileSunSub
        case .coral: .tileCoralSub
        case .mint: .tileMintSub
        case .sky: .tileSkySub
        case .pink: .tilePinkSub
        }
    }

    /// The translucent disc behind icons on a done tile.
    var chip: Color {
        self == .violet ? .white.opacity(0.18) : Color.onTile.opacity(0.10)
    }
}
