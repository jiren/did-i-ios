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
/// it can be logged, plain on a later day.
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
                icon
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
            .padding(10)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .foregroundStyle(content.isDone ? content.swatch.foreground : Color.ink)
        .background { background }
        .contentShape(.rect(cornerRadius: 22))
    }

    private var icon: some View {
        Image(systemName: content.kind.symbolName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(content.swatch.foreground)
            .frame(width: 32, height: 32)
            .background(content.isDone ? content.swatch.chip : content.swatch.background, in: .circle)
            .overlay(alignment: .bottomTrailing) {
                if content.isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 17, height: 17)
                        .background(Color.onTile, in: .circle)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        .offset(x: 5, y: 4)
                }
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        switch content.state {
        case .done: shape.fill(content.swatch.background)
        case .toLog: shape.strokeBorder(Color.ink, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
        case .upcoming: shape.fill(Color.surface)
        }
    }

    /// 30 pt, in a 44 pt target at the top right.
    private var photoButton: some View {
        Button(action: onPhoto) {
            Image(systemName: "camera.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(photoForeground)
                .frame(width: 30, height: 30)
                .background(photoBackground, in: .circle)
                .overlay(alignment: .topTrailing) {
                    if content.hasPhoto {
                        Circle()
                            .fill(Color.tileSun)
                            .overlay(Circle().strokeBorder(Color.onTile, lineWidth: 2))
                            .frame(width: 12, height: 12)
                            .offset(x: 3, y: -3)
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(2)
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

/// The dashed "Add task" tile at the end of a category's grid.
struct AddTaskTile: View {
    let category: CategoryRecord
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Color.clear.aspectRatio(1, contentMode: .fit)
                VStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(category.colour.foreground)
                        .frame(width: 32, height: 32)
                        .background(category.colour.background, in: .circle)
                    Text("Add task")
                        .font(.didFootnote)
                        .foregroundStyle(Color.ink)
                }
                .padding(8)
            }
            .frame(maxWidth: .infinity)
            .background(Color.surface, in: .rect(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.disabledFill, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
            }
            .contentShape(.rect(cornerRadius: 22))
        }
        .buttonStyle(TilePressStyle())
        .accessibilityLabel(Text("Add a task to \(category.name)"))
        .accessibilityIdentifier("section.\(category.name).add")
    }
}
