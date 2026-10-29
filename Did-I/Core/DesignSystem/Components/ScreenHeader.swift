import SwiftUI

/// A pushed screen's top: a round back button with its parent's name, then the title and a line under it
/// (`ActionButton.dc.html`).
struct ScreenHeader: View {
    let backTitle: String
    let title: String
    var subtitle: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                RoundIconButton(systemName: "chevron.left", label: String(localized: "Back to \(backTitle)")) { dismiss() }
                Text(backTitle)
                    .font(.didEmphasis)
                    .foregroundStyle(Color.muted)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.didScreenTitle)
                    .foregroundStyle(Color.ink)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(.didCaptionBody)
                        .foregroundStyle(Color.muted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A white rounded group of rows, as in Settings.
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Color.surface, in: .rect(cornerRadius: 18, style: .continuous))
    }
}

/// A row in a `SettingsCard`: a title and whatever control sits on the right.
struct SettingsRow<Accessory: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(spacing: 12) {
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
            Spacer(minLength: 8)
            accessory
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 56)
    }
}
