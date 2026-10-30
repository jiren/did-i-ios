import Foundation

/// A category's colour: one of the six tile colours, or one picked with the colour picker (stored as "#RRGGBB").
nonisolated enum CategoryColour: Hashable, Sendable {
    case swatch(TileSwatch)
    /// Uppercase "#RRGGBB".
    case custom(hex: String)

    static let violet = CategoryColour.swatch(.violet)
    static let sun = CategoryColour.swatch(.sun)
    static let coral = CategoryColour.swatch(.coral)
    static let mint = CategoryColour.swatch(.mint)
    static let sky = CategoryColour.swatch(.sky)
    static let pink = CategoryColour.swatch(.pink)

    /// The six drawn colours, in the picker's order.
    static let swatches: [CategoryColour] = TileSwatch.allCases.map { .swatch($0) }

    /// From a stored key: a swatch's ("violet") or a hex colour ("#5BC0FF").
    init?(key: String) {
        if let swatch = TileSwatch(key: key) {
            self = .swatch(swatch)
        } else if let rgb = Self.components(ofHex: key) {
            self = Self.custom(red: rgb.red, green: rgb.green, blue: rgb.blue)
        } else {
            return nil
        }
    }

    /// A picked colour, from 0–1 components.
    static func custom(red: Double, green: Double, blue: Double) -> CategoryColour {
        func byte(_ value: Double) -> Int { Int((min(max(value, 0), 1) * 255).rounded()) }
        return .custom(hex: String(format: "#%02X%02X%02X", byte(red), byte(green), byte(blue)))
    }

    var key: String {
        switch self {
        case .swatch(let swatch): swatch.key
        case .custom(let hex): hex
        }
    }

    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }

    /// 0–1 components of a custom colour; nil for a swatch (its colours live in the asset catalog).
    var components: (red: Double, green: Double, blue: Double)? {
        guard case .custom(let hex) = self else { return nil }
        return Self.components(ofHex: hex)
    }

    /// Whether white text reads better than ink on this colour (WCAG contrast). Swatches follow the design:
    /// white only on Violet.
    var prefersLightForeground: Bool {
        switch self {
        case .swatch(let swatch):
            return swatch == .violet
        case .custom:
            guard let rgb = components else { return false }
            let luminance = Self.luminance(rgb.red, rgb.green, rgb.blue)
            let againstWhite = 1.05 / (luminance + 0.05)
            let againstInk = (luminance + 0.05) / (Self.inkLuminance + 0.05)
            return againstWhite > againstInk
        }
    }

    var title: String {
        switch self {
        case .swatch(let swatch): swatch.title
        case .custom: String(localized: "Custom colour")
        }
    }

    // MARK: - Colour maths

    /// Ink, #17142A.
    private static let inkLuminance = luminance(23 / 255, 20 / 255, 42 / 255)

    private static func luminance(_ red: Double, _ green: Double, _ blue: Double) -> Double {
        func linear(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    private static func components(ofHex hex: String) -> (red: Double, green: Double, blue: Double)? {
        guard hex.hasPrefix("#"), hex.count == 7, let value = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        return (Double((value >> 16) & 0xFF) / 255, Double((value >> 8) & 0xFF) / 255, Double(value & 0xFF) / 255)
    }
}
