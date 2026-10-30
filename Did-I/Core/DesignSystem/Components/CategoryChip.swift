import SwiftUI

/// A category as a capsule: Today's filter chips (a faint ink fill, ink when selected) and the Add sheet's "Add to"
/// chips (outlined, the category's colour when selected).
struct CategoryChip: View {
    enum Style {
        case filter, addTo
    }

    let title: String
    var icon: CategoryIcon?
    var colour: CategoryColour = .violet
    let isSelected: Bool
    var style: Style = .filter
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    if style == .filter {
                        CategoryBadge(icon: icon, colour: colour, size: 20, cornerRadius: nil)
                    } else {
                        Image(systemName: icon.symbolName)
                            .font(.system(size: 13, weight: .semibold))
                            .accessibilityHidden(true)
                    }
                }
                Text(title)
                    .font(.didPill)
                    .lineLimit(1)
            }
            .padding(.leading, icon != nil && style == .filter ? 10 : 14)
            .padding(.trailing, style == .filter ? 12 : 14)
            .frame(minHeight: 44)
            .foregroundStyle(foreground)
            .background(background, in: .capsule)
            .overlay(Capsule().strokeBorder(border, lineWidth: 2))
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var foreground: Color {
        switch style {
        case .filter: isSelected ? .ground : .ink
        case .addTo: isSelected ? colour.foreground : .ink
        }
    }

    private var background: Color {
        switch style {
        case .filter: isSelected ? .ink : Color.ink.opacity(0.06)
        case .addTo: isSelected ? colour.background : .surface
        }
    }

    private var border: Color {
        switch style {
        case .filter: .clear
        case .addTo: isSelected ? colour.background : .line
        }
    }
}

/// The dashed + at the end of the filters: New category.
struct NewCategoryChip: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(Color.ink)
                .frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(Color.disabledFill, style: StrokeStyle(lineWidth: 2, dash: [5, 4])))
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("New category"))
    }
}
