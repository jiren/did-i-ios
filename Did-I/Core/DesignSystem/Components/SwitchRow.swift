import SwiftUI

/// A white rounded row with a title, a hint and a switch (Detail, Action Button settings).
struct SwitchRow: View {
    let title: String
    let subtitle: String?
    var symbolName: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.onTile)
                        .frame(width: 36, height: 36)
                        .background(Color.tileSun, in: .circle)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.didRowTitle)
                        .foregroundStyle(Color.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(.didFootnoteRegular)
                            .foregroundStyle(Color.muted)
                    }
                }
            }
        }
        .tint(Color.tileViolet)
        .padding(.vertical, 10)
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .frame(minHeight: 60)
        .background(Color.surface, in: .rect(cornerRadius: 18, style: .continuous))
    }
}
