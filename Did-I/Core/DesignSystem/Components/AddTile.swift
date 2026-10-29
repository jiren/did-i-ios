import SwiftUI

/// The dashed "Add checks" tile at the end of Today's grid.
struct AddTile: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.tileViolet, in: .circle)
                Text("Add checks")
                    .font(.didTileAction)
                    .foregroundStyle(Color.linkText)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 196, maxHeight: .infinity)
            .background(Color.surface, in: .rect(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.disabledFill, style: StrokeStyle(lineWidth: 2.5, dash: [7, 6]))
            }
            .contentShape(.rect(cornerRadius: 28))
        }
        .buttonStyle(TilePressStyle())
    }
}
