import SwiftUI

/// What a square task tile shows; built by the view model so the view does no formatting.
struct TaskTileContent: Equatable {
    enum State: Equatable {
        /// Logged in the day, with its time ("8:42 AM").
        case done(time: String)
        /// Today, not logged yet: "Tap to log".
        case toLog
        /// A later day: "Upcoming", and it can't be logged.
        case upcoming
    }

    var name: String
    var kind: CheckKind
    var swatch: TileSwatch
    var state: State
    var hasPhoto: Bool
    /// "Stove off, not logged — tap to log".
    var accessibilityLabel: String
    /// "Log Stove off with a photo" or "Retake photo for Front door locked".
    var photoButtonLabel: String

    var isDone: Bool {
        if case .done = state { return true }
        return false
    }

    var canLog: Bool { state != .upcoming }

    var statusText: String {
        switch state {
        case .done(let time): time
        case .toLog: String(localized: "Tap to log")
        case .upcoming: String(localized: "Upcoming")
        }
    }
}

/// A task in a category's 3-column grid (`Main.dc.html`): filled in its colour once done, a dashed outline while
/// it can be logged, plain on a later day. `TaskRow` is the same task in the list layout.
struct TaskTile: View {
    let content: TaskTileContent
    let onLog: () -> Void
    let onPhoto: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onLog) { label }
                .buttonStyle(TilePressStyle())
                .disabled(!content.canLog)
                .accessibilityLabel(content.accessibilityLabel)
                .accessibilityIdentifier("tile.\(content.name)")
            if content.canLog {
                photoButton
            }
        }
    }

    private var label: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.aspectRatio(1, contentMode: .fit)
            VStack(alignment: .leading, spacing: 2) {
                TaskIcon(content: content)
                Spacer(minLength: 6)
                Text(content.name)
                    .font(.didSmallTileName)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(content.statusText)
                    .font(.didMicro)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(content.isDone ? content.swatch.secondary : Color.muted)
            }
            .padding(9)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .foregroundStyle(content.isDone ? content.swatch.foreground : Color.ink)
        .background { background }
        .contentShape(.rect(cornerRadius: 20))
    }

    private var background: some View {
        TaskFill(state: content.state, swatch: content.swatch, cornerRadius: 20)
    }

    private var photoButton: some View {
        TaskPhotoButton(content: content, action: onPhoto)
            .padding(2)
    }
}

/// The same task as a 52 pt row, for Today's list layout (`Main.dc.html`, view "list").
struct TaskRow: View {
    let content: TaskTileContent
    let onLog: () -> Void
    let onPhoto: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: onLog) {
                HStack(spacing: 12) {
                    TaskIcon(content: content)
                    // At accessibility sizes the status goes under the name, and the name may wrap.
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 2) { name.lineLimit(3); status }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    } else {
                        name.lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                        status
                    }
                }
                .foregroundStyle(content.isDone ? content.swatch.foreground : Color.ink)
                .padding(.leading, 10)
                .padding(.trailing, content.canLog ? 56 : 14)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background { TaskFill(state: content.state, swatch: content.swatch, cornerRadius: 16) }
                .contentShape(.rect(cornerRadius: 16))
            }
            .buttonStyle(TilePressStyle())
            .disabled(!content.canLog)
            .accessibilityLabel(content.accessibilityLabel)
            .accessibilityIdentifier("tile.\(content.name)")
            if content.canLog {
                TaskPhotoButton(content: content, action: onPhoto)
                    .padding(.trailing, 4)
            }
        }
    }
}

private extension TaskRow {
    var name: some View {
        Text(content.name).font(.didEmphasis)
    }

    var status: some View {
        Text(content.statusText)
            .font(.didMicro)
            .lineLimit(1)
            .foregroundStyle(content.isDone ? content.swatch.secondary : Color.muted)
    }
}

/// A task's 30 pt icon disc, with the check badge once done.
private struct TaskIcon: View {
    let content: TaskTileContent

    var body: some View {
        Image(systemName: content.kind.symbolName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(content.swatch.foreground)
            .frame(width: 30, height: 30)
            .background(content.isDone ? content.swatch.chip : content.swatch.background, in: .circle)
            .overlay(alignment: .bottomTrailing) {
                if content.isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(Color.onTile, in: .circle)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        .offset(x: 5, y: 4)
                }
            }
            .accessibilityHidden(true)
    }
}

/// Done: the task's colour. To log: a dashed ink outline. A later day: plain.
private struct TaskFill: View {
    let state: TaskTileContent.State
    let swatch: TileSwatch
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        switch state {
        case .done: shape.fill(swatch.background)
        case .toLog: shape.strokeBorder(Color.ink, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
        case .upcoming: shape.fill(Color.surface)
        }
    }
}

/// The 28 pt camera, in a 44 pt target, with the sun dot once a photo exists.
private struct TaskPhotoButton: View {
    let content: TaskTileContent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "camera.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: 28, height: 28)
                .background(background, in: .circle)
                .overlay(alignment: .topTrailing) {
                    if content.hasPhoto {
                        Circle()
                            .fill(Color.tileSun)
                            .overlay(Circle().strokeBorder(Color.onTile, lineWidth: 2))
                            .frame(width: 11, height: 11)
                            .offset(x: 3, y: -3)
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(content.photoButtonLabel)
        .accessibilityIdentifier("tile.\(content.name).photo")
    }

    private var background: Color {
        if content.hasPhoto { return .onTile }
        return content.isDone ? content.swatch.chip : Color.ink.opacity(0.10)
    }

    private var foreground: Color {
        if content.hasPhoto { return .white }
        return content.isDone ? content.swatch.foreground : .ink
    }
}
