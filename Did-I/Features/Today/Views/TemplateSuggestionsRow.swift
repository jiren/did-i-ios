import SwiftUI

/// "Start from a template" on Today (Phase 28): a sideways row of templates not used yet, then See all. Picking one
/// opens New category on its form, filled in.
struct TemplateSuggestionsRow: View {
    let items: [CategoryTemplateItem]
    let onPick: (CategoryTemplate) -> Void
    let onSeeAll: () -> Void

    @ScaledMetric(relativeTo: .body) private var cardWidth = 168.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                SectionLabel(title: String(localized: "Start from a template"))
                Spacer(minLength: 8)
                Button(String(localized: "See all"), action: onSeeAll)
                    .font(.didFootnote)
                    .foregroundStyle(Color.linkText)
                    .frame(minHeight: 44)
                    .accessibilityLabel(Text("See all templates"))
                    .accessibilityIdentifier("today.templates.seeAll")
            }
            .padding(.horizontal, 20)
            ScrollView(.horizontal) {
                // A plain stack (six cards at most), so every card takes the tallest one's height.
                HStack(alignment: .top, spacing: 10) {
                    ForEach(items) { item in
                        TemplateCard(item: item) { onPick(item.template) }
                            .frame(width: cardWidth)
                            .accessibilityIdentifier("today.template.\(item.template.id)")
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.templates")
    }
}
