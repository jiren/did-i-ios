import SwiftUI

/// A category's icon on its colour: 40 pt in a section header, 36 in Coming up, 22 in a chip.
struct CategoryBadge: View {
    let icon: CategoryIcon
    let colour: CategoryColour
    var size: CGFloat = 40
    /// Nil makes it a circle.
    var cornerRadius: CGFloat? = 14

    var body: some View {
        Image(systemName: icon.symbolName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(colour.foreground)
            .frame(width: size, height: size)
            .background(colour.background, in: shape)
            .accessibilityHidden(true)
    }

    private var shape: some Shape {
        RoundedRectangle(cornerRadius: cornerRadius ?? size / 2, style: .continuous)
    }
}
