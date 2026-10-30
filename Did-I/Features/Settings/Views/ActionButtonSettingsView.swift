import SwiftUI

/// Settings › Action Button (`ActionButton.dc.html`).
struct ActionButtonSettingsView: View {
    @Bindable var settings: AppSettings
    let checks: [CheckRecord]
    /// "Stove off · Bedtime" where two categories share a name.
    var titles: [UUID: String] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(
                    backTitle: String(localized: "Settings"),
                    title: String(localized: "Action Button"),
                    subtitle: String(localized: "One press logs it. Pick what a press does.")
                )
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(title: String(localized: "A press logs"))
                    option(
                        title: String(localized: "Ask me which"),
                        hint: String(localized: "Quick picker of your checks"),
                        swatch: nil,
                        isSelected: selectedID == nil
                    ) { settings.actionButtonCheckID = nil }
                    ForEach(Array(checks.enumerated()), id: \.element.id) { position, check in
                        option(
                            title: titles[check.id] ?? check.name,
                            hint: String(localized: "Logs straight away"),
                            swatch: TileSwatch.at(position: position),
                            isSelected: selectedID == check.id
                        ) { settings.actionButtonCheckID = check.id }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(title: String(localized: "After a press"))
                    SwitchRow(title: String(localized: "Open camera"), subtitle: String(localized: "Snap proof right away"),
                              isOn: $settings.actionButtonOpensCamera)
                    SwitchRow(title: String(localized: "Strong haptic"), subtitle: String(localized: "Feel it, so you don’t doubt it"),
                              isOn: $settings.actionButtonStrongHaptic)
                }
                setupHelp
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.ground)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    /// A removed check falls back to asking.
    private var selectedID: UUID? {
        settings.actionButtonCheckID.flatMap { id in checks.contains { $0.id == id } ? id : nil }
    }

    private func option(title: String, hint: String, swatch: TileSwatch?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.tileViolet : Color.disabledFill)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.didRowTitle).foregroundStyle(Color.ink)
                    Text(hint).font(.didFootnoteRegular).foregroundStyle(Color.muted)
                }
                Spacer()
                Circle()
                    .fill(swatch?.background ?? Color.ink)
                    .frame(width: 14, height: 14)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 60)
            .background(Color.surface, in: .rect(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? Color.tileViolet : Color.surface, lineWidth: 2)
            }
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var setupHelp: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Set up the button")
                .font(.didRowTitle)
                .foregroundStyle(Color.ink)
            Text(ActionButtonSupport.isAvailable
                 ? String(localized: "In the Settings app, open Action Button, swipe to Controls, and choose Did I? › Log a check.")
                 : String(localized: "This iPhone has no Action Button. The same choice applies to the Did I? control in Control Center."))
                .font(.didFootnoteRegular)
                .foregroundStyle(Color.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sand, in: .rect(cornerRadius: 18, style: .continuous))
    }
}
