import SwiftUI

/// The Today tab's ring: today's due tasks done, ink on a faint track.
struct ProgressRing: View {
    /// 0 to 1.
    let fraction: Double
    var colour: Color = .onTile
    var lineWidth: CGFloat = 3.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(colour.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(colour, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 16 + lineWidth, height: 16 + lineWidth)
        .frame(width: 24, height: 24)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: fraction)
        .accessibilityHidden(true)
    }
}
