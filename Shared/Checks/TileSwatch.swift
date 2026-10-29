import Foundation

/// The tile colours, cycled by a check's position on Today (`Main.dc.html`'s palette).
nonisolated enum TileSwatch: Int, CaseIterable, Sendable {
    case violet, sun, coral, mint, sky, pink

    static func at(position: Int) -> TileSwatch {
        allCases[((position % allCases.count) + allCases.count) % allCases.count]
    }
}
