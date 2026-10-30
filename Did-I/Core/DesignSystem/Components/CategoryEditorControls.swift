import SwiftUI

/// The live preview at the top of New category (`NewCategory.dc.html`).
struct CategoryPreviewCard: View {
    let name: String
    let icon: CategoryIcon
    let colour: TileSwatch
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

/// The 12 category icons in a 6-column grid; the chosen one sits on the category's colour.
struct CategoryIconGrid: View {
    @Binding var selection: CategoryIcon
    let colour: TileSwatch

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(CategoryIcon.allCases, id: \.self) { icon in
                let isOn = icon == selection
                Button { selection = icon } label: {
                    Image(systemName: icon.symbolName)
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
                .buttonStyle(.plain)
                .accessibilityLabel(Text("\(icon.title) icon"))
                .accessibilityAddTraits(isOn ? .isSelected : [])
                .accessibilityIdentifier("category.icon.\(icon.rawValue)")
            }
        }
    }
}

/// The six colours as round swatches; the chosen one gets an ink ring.
struct ColourSwatchPicker: View {
    @Binding var selection: TileSwatch

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TileSwatch.allCases, id: \.self) { swatch in
                let isOn = swatch == selection
                Button { selection = swatch } label: {
                    Capsule()
                        .fill(swatch.background)
                        .overlay {
                            if isOn {
                                Capsule().strokeBorder(Color.ink, lineWidth: 3)
                                Capsule().inset(by: 3).strokeBorder(Color.ground, lineWidth: 3)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(swatch.title)
                .accessibilityAddTraits(isOn ? .isSelected : [])
                .accessibilityIdentifier("category.colour.\(swatch.key)")
            }
        }
    }
}

/// "On": seven weekday buttons, the chosen one in the category's colour.
struct WeekdayPicker: View {
    /// 1 (Sunday) to 7.
    @Binding var selection: Int
    let colour: TileSwatch
    var calendar: Calendar = .autoupdatingCurrent

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekdays, id: \.self) { weekday in
                let isOn = weekday == selection
                Button { selection = weekday } label: {
                    Text(calendar.veryShortStandaloneWeekdaySymbols[weekday - 1])
                        .font(.didEmphasis)
                        .foregroundStyle(isOn ? colour.foreground : Color.ink)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(isOn ? colour.background : Color.surface, in: .capsule)
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
        (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
    }
}

/// A task on New category: a dot in the category's colour, the name and a remove button.
struct CategoryTaskRow: View {
    let name: String
    let colour: TileSwatch
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(colour.background).frame(width: 10, height: 10).accessibilityHidden(true)
            Text(name).font(.didRowTitle).frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.muted)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Remove \(name)"))
        }
        .foregroundStyle(Color.ink)
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .frame(minHeight: 52)
        .background(Color.surface, in: .rect(cornerRadius: 16, style: .continuous))
    }
}
