import SwiftUI

/// One log on Detail's timeline: a dot (filled for the newest), a rail, the time and where it came from.
struct TimelineRow: View {
    let title: String
    let subtitle: String
    let isNewest: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .strokeBorder(Color.tileViolet, lineWidth: isNewest ? 0 : 3)
                    .background(isNewest ? Color.tileViolet : Color.clear, in: .circle)
                    .frame(width: 14, height: 14)
                    .padding(.top, 4)
                Rectangle()
                    .fill(isLast ? Color.clear : Color.line)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 14)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.didRowTitle)
                    .foregroundStyle(Color.ink)
                Text(subtitle)
                    .font(.didCaptionBody)
                    .foregroundStyle(Color.muted)
            }
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
}
