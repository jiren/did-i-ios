import SwiftUI

/// The date line, Settings and the "Did I?" title.
struct TodayHeader: View {
    let dateText: String
    let onSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(dateText)
                    .font(.didSubheadline)
                    .foregroundStyle(Color.muted)
                    .accessibilityIdentifier("today.date")
                Spacer()
                RoundIconButton(systemName: "gearshape.fill", label: String(localized: "Settings"), action: onSettings)
                    .accessibilityIdentifier("today.settings")
            }
            Text("Did I?")
                .font(.didHero)
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}
