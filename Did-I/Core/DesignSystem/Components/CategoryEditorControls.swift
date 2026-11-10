import SwiftUI

/// The live preview at the top of New category (`NewCategory.dc.html`).
struct CategoryPreviewCard: View {
    let name: String
    let icon: CategoryIcon
    let colour: CategoryColour
    /// "Once · Fri, Nov 6".
    let repeatSummary: String
    /// "3 tasks · Reminder at 8:00 PM".
    let detail: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon.symbolName)
                .font(.system(size: 28, weight: .semibold))
                .frame(width: 64, height: 64)
                .background(colour.chip, in: .rect(cornerRadius: 20, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.didPreviewTitle).lineLimit(2)
                Text(repeatSummary).font(.didPill)
                Text(detail).font(.didFootnote)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(colour.foreground)
        .padding(18)
        .background(colour.background, in: .rect(cornerRadius: 26, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// The 12 drawn icons, then the chosen library icon (if any), then More icons. The chosen one sits on the
/// category's colour.
struct CategoryIconGrid: View {
    @Binding var selection: CategoryIcon
    let colour: CategoryColour
    let onMore: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    private var icons: [CategoryIcon] {
        selection.isFeatured ? CategoryIcon.featured : CategoryIcon.featured + [selection]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(icons, id: \.self) { icon in
                let isOn = icon == selection
                Button { selection = icon } label: {
                    cell(Image(systemName: icon.symbolName), isOn: isOn)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("\(icon.title) icon"))
                .accessibilityAddTraits(isOn ? .isSelected : [])
                .accessibilityIdentifier("category.icon.\(icon.rawValue)")
            }
            Button(action: onMore) {
                cell(Image(systemName: "ellipsis"), isOn: false)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("More icons"))
            .accessibilityIdentifier("category.icon.more")
        }
    }

    private func cell(_ image: Image, isOn: Bool) -> some View {
        image
            .font(.system(size: 19, weight: .semibold))
            .foregroundStyle(isOn ? colour.foreground : Color.ink)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(isOn ? colour.background : Color.surface, in: .rect(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isOn ? Color.ink : .clear, lineWidth: 2)
            }
            .contentShape(.rect(cornerRadius: 14))
    }
}

/// The six colours as round swatches, then a custom one (a rainbow ring until a colour is picked); the chosen one
/// gets an ink ring.
struct ColourSwatchPicker: View {
    @Binding var selection: CategoryColour
    /// Opens the colour picker.
    let onCustom: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(CategoryColour.swatches, id: \.self) { colour in
                Button { selection = colour } label: {
                    swatch(Capsule().fill(colour.background), isOn: colour == selection)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(colour.title)
                .accessibilityAddTraits(colour == selection ? .isSelected : [])
                .accessibilityIdentifier("category.colour.\(colour.key)")
            }
            Button(action: onCustom) {
                if selection.isCustom {
                    swatch(Capsule().fill(selection.background), isOn: true)
                } else {
                    swatch(
                        Capsule()
                            .strokeBorder(AngularGradient(colors: Self.rainbow, center: .center), lineWidth: 6)
                            .overlay { Image(systemName: "plus").font(.system(size: 14, weight: .heavy)).foregroundStyle(Color.ink) },
                        isOn: false
                    )
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Custom colour"))
            .accessibilityAddTraits(selection.isCustom ? .isSelected : [])
            .accessibilityIdentifier("category.colour.custom")
        }
    }

    private static let rainbow: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red]

    private func swatch(_ fill: some View, isOn: Bool) -> some View {
        fill
            .overlay {
                if isOn {
                    Capsule().strokeBorder(Color.ink, lineWidth: 3)
                    Capsule().inset(by: 3).strokeBorder(Color.ground, lineWidth: 3)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(.capsule)
    }
}

/// "On": seven weekday buttons, the chosen ones in the category's colour. With `allowsSeveral`, each tap adds or
/// removes a day (at least one stays); otherwise a tap picks the one day.
struct WeekdayPicker: View {
    /// 1 (Sunday) to 7.
    @Binding var selection: Set<Int>
    var allowsSeveral = false
    let colour: CategoryColour
    var calendar: Calendar = .autoupdatingCurrent
    /// Unchosen days; the ground when the picker sits on a white card.
    var offBackground: Color = .surface

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekdays, id: \.self) { weekday in
                let isOn = selection.contains(weekday)
                Button { toggle(weekday) } label: {
                    Text(calendar.veryShortStandaloneWeekdaySymbols[weekday - 1])
                        .font(.didEmphasis)
                        .foregroundStyle(isOn ? colour.foreground : Color.ink)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(isOn ? colour.background : offBackground, in: .capsule)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(calendar.standaloneWeekdaySymbols[weekday - 1])
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }

    /// In the calendar's week order (Monday first in many places).
    private var weekdays: [Int] {
        RepeatRule.weekOrder(Set(1...7), calendar: calendar)
    }

    private func toggle(_ weekday: Int) {
        guard allowsSeveral else {
            selection = [weekday]
            return
        }
        if selection.contains(weekday) {
            if selection.count > 1 { selection.remove(weekday) }
        } else {
            selection.insert(weekday)
        }
    }
}

/// A task on New category: a dot in the category's colour, its name to edit in place, and a remove button.
struct CategoryTaskRow: View {
    @Binding var name: String
    let colour: CategoryColour
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(colour.background).frame(width: 10, height: 10).accessibilityHidden(true)
            TextField(String(localized: "Task"), text: $name)
                .font(.didRowTitle)
                .submitLabel(.done)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("category.taskName.\(name)")
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.muted)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Remove \(name)"))
            .accessibilityIdentifier("category.removeTask.\(name)")
        }
        .foregroundStyle(Color.ink)
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .frame(minHeight: 52)
        .background(Color.surface, in: .rect(cornerRadius: 16, style: .continuous))
    }
}
