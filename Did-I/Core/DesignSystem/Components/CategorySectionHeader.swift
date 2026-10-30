import SwiftUI

/// A category's heading on Today: icon on colour, name, repeat and "2/4".
struct CategorySectionHeader: View {
    let category: CategoryRecord
    let repeatLabel: String
    let progressText: String

    var body: some View {
        HStack(spacing: 12) {
            CategoryBadge(icon: category.icon, colour: category.colour)
            VStack(alignment: .leading, spacing: 0) {
                Text(category.name)
                    .font(.didTileName)
                    .accessibilityAddTraits(.isHeader)
                Text(repeatLabel)
                    .font(.didFootnote)
                    .foregroundStyle(Color.muted)
            }
            Spacer(minLength: 8)
            Text(progressText)
                .font(.didPill)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.surface, in: .capsule)
                .accessibilityLabel(Text("\(progressText) done"))
        }
        .foregroundStyle(Color.ink)
    }
}
