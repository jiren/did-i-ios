import SwiftUI

/// A category due soon, under "Coming up": its icon, name, "2 checks · Every Friday" and when.
struct ComingUpRow: View {
    let upcoming: DayAgenda.Upcoming
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                CategoryBadge(icon: upcoming.category.icon, colour: upcoming.category.colour, size: 36, cornerRadius: 12)
                VStack(alignment: .leading, spacing: 0) {
                    Text(upcoming.category.name).font(.didEmphasis)
                    Text(upcoming.detail).font(.didFootnoteRegular).foregroundStyle(Color.muted)
                }
                Spacer(minLength: 8)
                Text(upcoming.when)
                    .font(.didPill)
                    .foregroundStyle(Color.linkText)
            }
            .foregroundStyle(Color.ink)
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 14))
            .frame(minHeight: 56)
            .background(Color.surface, in: .rect(cornerRadius: 18, style: .continuous))
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(TilePressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("comingUp.\(upcoming.category.name)")
    }
}

/// "Nothing due" with why, when no category is due on the selected day.
struct NothingDueCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nothing due").font(.didSheetTitle.weight(.bold))
            Text(text).font(.didCaptionBody).foregroundStyle(Color.muted)
        }
        .foregroundStyle(Color.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color.surface, in: .rect(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// The wide dashed "Add checks" button under Today's sections.
struct AddChecksButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Add checks", systemImage: "plus")
                .font(.didRowTitle)
                .foregroundStyle(Color.linkText)
                .frame(maxWidth: .infinity, minHeight: 56)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.disabledFill, style: StrokeStyle(lineWidth: 2.5, dash: [7, 6]))
                }
                .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(TilePressStyle())
    }
}
