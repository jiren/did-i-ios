import SwiftUI

/// A category as a capsule: Today's filter chips (ink when selected) and the Add sheet's "Add to" chips (the
/// category's colour when selected).
struct CategoryChip: View {
    enum Style {
        case filter, addTo
    }

    let title: String
    var icon: CategoryIcon?
    var colour: TileSwatch = .violet
    let isSelected: Bool
    var style: Style = .filter
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    if style == .filter {
                        CategoryBadge(icon: icon, colour: colour, size: 22, cornerRadius: nil)
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
            .padding(.leading, icon != nil && style == .filter ? 9 : 14)
            .padding(.trailing, 14)
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
        case .filter: isSelected ? .ink : .clear
        case .addTo: isSelected ? colour.background : .surface
        }
    }

    private var border: Color {
        switch style {
        case .filter: .ink
        case .addTo: isSelected ? colour.background : .line
        }
    }
}

/// The dashed "New category" chip at the end of the filters.
struct NewCategoryChip: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text("New category").font(.didPill)
            } icon: {
                Image(systemName: "plus").font(.system(size: 12, weight: .heavy))
            }
            .labelStyle(.titleAndIcon)
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .overlay(Capsule().strokeBorder(Color.disabledFill, style: StrokeStyle(lineWidth: 2, dash: [5, 4])))
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}
