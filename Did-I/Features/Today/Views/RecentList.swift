import SwiftUI

/// Today's latest three logs; each opens its check.
struct RecentList: View {
    let rows: [RecentRow]
    let onOpen: (UUID) -> Void
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recent")
                    .font(.didSection)
                    .foregroundStyle(Color.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("See all", action: onSeeAll)
                    .font(.didEmphasis)
                    .foregroundStyle(Color.linkText)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("today.seeAll")
            }
            ForEach(rows) { row in
                Button { onOpen(row.checkID) } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(row.swatch.background)
                            .frame(width: 10, height: 10)
                            .accessibilityHidden(true)
                        Text(row.title)
                            .font(.didSubheadline)
                            .foregroundStyle(Color.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(row.meta)
                            .font(.didCaptionBody)
                            .foregroundStyle(Color.muted)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(minHeight: 48)
                    .background(Color.surface, in: .rect(cornerRadius: 18, style: .continuous))
                    .contentShape(.rect(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
            }
        }
    }
}
