import SwiftUI

/// A template: its icon on its colour, name, "Every day · 5 tasks", and "Added" when a category has its name. On
/// New category's gallery and Today's "Start from a template" row.
struct TemplateCard: View {
    let item: CategoryTemplateItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    CategoryBadge(icon: item.template.icon, colour: item.template.colour, size: 40)
                    Spacer(minLength: 4)
                    if item.isAdded {
                        Text("Added")
                            .font(.didMicro)
                            .foregroundStyle(Color.muted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.sand, in: .capsule)
                    }
                }
                Text(item.template.name)
                    .font(.didBarTitle)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.detail)
                    .font(.didFootnoteRegular)
                    .foregroundStyle(Color.muted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 132, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.surface, in: .rect(cornerRadius: 22, style: .continuous))
            .contentShape(.rect(cornerRadius: 22))
        }
        .buttonStyle(TilePressStyle())
        .accessibilityElement(children: .combine)
    }
}
