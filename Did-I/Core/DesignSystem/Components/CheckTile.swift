import SwiftUI

/// What a check tile shows; built by the view model so the view does no formatting.
struct CheckTileContent: Equatable {
    var name: String
    var kind: CheckKind
    var swatch: TileSwatch
    var isDone: Bool
    var hasPhoto: Bool
    /// "8:42 AM", or "Tap to log".
    var timeText: String
    /// "2h 9m ago · photo", or "Not yet today".
    var detailText: String
    var accessibilityLabel: String
    var photoButtonLabel: String
}

/// A check on Today (`Main.dc.html`): filled in its colour once logged today, a dashed outline before.
struct CheckTile: View {
    let content: CheckTileContent
    let onLog: () -> Void
    let onPhoto: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Button(action: onLog) { label }
                .buttonStyle(TilePressStyle())
                .accessibilityLabel(content.accessibilityLabel)
                .accessibilityIdentifier("tile.\(content.name)")
            photoButton
                .padding(12)
        }
        .frame(maxHeight: .infinity)
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                TileIcon(kind: content.kind, swatch: content.swatch, isDone: content.isDone)
                Spacer(minLength: 8)
                if content.isDone {
                    DoneBadge()
                }
            }
            Text(content.name)
                .font(.didTileName)
                .multilineTextAlignment(.leading)
                .padding(.top, 18)
            Text(content.timeText)
                .font(.didTileTime)
                .padding(.top, 4)
            Text(content.detailText)
                .font(.didFootnote)
                .foregroundStyle(content.isDone ? content.swatch.secondary : Color.muted)
                .padding(.top, 2)
                .padding(.trailing, 48)
        }
        .foregroundStyle(content.isDone ? content.swatch.foreground : Color.ink)
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 20, trailing: 16))
        .frame(maxWidth: .infinity, minHeight: 196, maxHeight: .infinity, alignment: .topLeading)
        .background { background }
        .contentShape(.rect(cornerRadius: 28))
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        if content.isDone {
            shape.fill(content.swatch.background)
        } else {
            shape.strokeBorder(Color.ink, style: StrokeStyle(lineWidth: 2.5, dash: [7, 6]))
        }
    }

    private var photoButton: some View {
        Button(action: onPhoto) {
            Image(systemName: "camera.fill")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(photoForeground)
                .background(photoBackground, in: .circle)
                .overlay(alignment: .topTrailing) {
                    if content.hasPhoto {
                        PhotoBadge().offset(x: 3, y: -3)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(content.photoButtonLabel)
        .accessibilityIdentifier("tile.\(content.name).photo")
    }

    private var photoBackground: Color {
        if content.hasPhoto { return .onTile }
        return content.isDone ? content.swatch.chip : Color.ink.opacity(0.10)
    }

    private var photoForeground: Color {
        if content.hasPhoto { return .white }
        return content.isDone ? content.swatch.foreground : .ink
    }
}

/// The 44 pt disc with the check's symbol.
struct TileIcon: View {
    let kind: CheckKind
    let swatch: TileSwatch
    let isDone: Bool

    var body: some View {
        Image(systemName: kind.symbolName)
            .font(.system(size: 19, weight: .semibold))
            .foregroundStyle(swatch.foreground)
            .frame(width: 44, height: 44)
            .background(isDone ? swatch.chip : swatch.background, in: .circle)
            .accessibilityHidden(true)
    }
}

private struct DoneBadge: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 13, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Color.onTile, in: .circle)
            .accessibilityHidden(true)
    }
}

private struct PhotoBadge: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 8, weight: .black))
            .foregroundStyle(Color.onTile)
            .frame(width: 18, height: 18)
            .background(Color.tileSun, in: .circle)
            .overlay(Circle().strokeBorder(Color.onTile, lineWidth: 2))
            .accessibilityHidden(true)
    }
}

/// Shrinks a tile slightly while pressed.
struct TilePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}
