import SwiftUI

/// A category's heading on Today (`Main.dc.html`): one button that opens or closes the section (icon, name, the
/// repeat or "All done · last 8:42 AM", the progress pill and a chevron), and a + to add tasks to it.
struct CategorySectionHeader: View {
    let category: CategoryRecord
    /// "Every Friday", or "All done · last 8:42 AM".
    let meta: String
    /// "2/4", or "✓ 2/2".
    let progressText: String
    let isAllDone: Bool
    let isExpanded: Bool
    let onToggle: () -> Void
    let onAdd: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    CategoryBadge(icon: category.icon, colour: category.colour, size: 32, cornerRadius: 10)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(category.name)
                            .font(.didBarTitle)
                        Text(meta)
                            .font(.didMeta)
                            .foregroundStyle(Color.muted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(progressText)
                        .font(.didLabel)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(isAllDone ? Color.tileMint : Color.surface, in: .capsule)
                        .foregroundStyle(isAllDone ? Color.onTile : Color.ink)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.muted)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(reduceMotion ? nil : .snappy, value: isExpanded)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(Color.ink)
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityValue(isExpanded ? Text("Expanded") : Text("Collapsed"))
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("section.\(category.name)")

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(category.colour.foreground)
                    .frame(width: 28, height: 28)
                    .background(category.colour.background, in: .circle)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Add a task to \(category.name)"))
            .accessibilityIdentifier("section.\(category.name).add")
        }
    }
}
