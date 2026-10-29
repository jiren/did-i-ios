import SwiftUI

struct TodayHeader: View {
    let dateText: String
    let summary: TodaySummary
    let showsSummary: Bool
    let onSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(dateText)
                    .font(.didSubheadline)
                    .foregroundStyle(Color.muted)
                Spacer()
                RoundIconButton(systemName: "gearshape.fill", label: String(localized: "Settings"), action: onSettings)
                    .accessibilityIdentifier("today.settings")
            }
            Text("Did I?")
                .font(.didHero)
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
            if showsSummary {
                FlowLayout(spacing: 10) {
                    ProgressPill(text: summary.progressText)
                    Text(summary.summaryText)
                        .font(.didEmphasis)
                        .foregroundStyle(Color.ink)
                        .padding(.vertical, 7)
                }
                .padding(.top, 10)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("today.summary")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}
