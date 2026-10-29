import SwiftUI

/// "Logged · Front door locked" with Undo, shown for a few seconds after a log.
struct UndoToast: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(Color.onTile)
                .frame(width: 24, height: 24)
                .background(Color.tileMint, in: .circle)
                .accessibilityHidden(true)
            Text(message)
                .font(.didSubheadline)
                .foregroundStyle(Color.onChrome)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onUndo) {
                Text("Undo")
                    .font(.didEmphasis)
                    .foregroundStyle(Color.onTile)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .background(Color.tileSun, in: .rect(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("toast.undo")
        }
        .padding(6)
        .padding(.leading, 10)
        .background(Color.chrome, in: .rect(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isStaticText)
    }
}
