import AppIntents
import SwiftUI
import WidgetKit

struct OverviewEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct OverviewProvider: TimelineProvider {
    func placeholder(in context: Context) -> OverviewEntry {
        OverviewEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (OverviewEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task { @MainActor in
            completion(OverviewEntry(date: Date(), snapshot: WidgetSnapshot.read(services: IntentServices.shared, now: Date())))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OverviewEntry>) -> Void) {
        Task { @MainActor in
            let now = Date()
            let snapshot = WidgetSnapshot.read(services: IntentServices.shared, now: now)
            let tomorrow = WidgetSnapshot(
                checks: snapshot.checks.map(\.nextDay),
                hidesNames: snapshot.hidesNames,
                nextDayStart: snapshot.nextDayStart
            )
            completion(Timeline(
                entries: [OverviewEntry(date: now, snapshot: snapshot), OverviewEntry(date: snapshot.nextDayStart, snapshot: tomorrow)],
                policy: .after(snapshot.nextDayStart)
            ))
        }
    }
}

/// Up to four checks due today on the Home Screen; tap one to log it.
struct ChecksOverviewWidget: Widget {
    static let kind = "ChecksOverviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: OverviewProvider()) { entry in
            OverviewView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Today’s checks")
        .description("The first four checks due today. Tap one to log it.")
        .supportedFamilies([.systemMedium])
    }
}

struct OverviewView: View {
    let snapshot: WidgetSnapshot

    private var checks: [WidgetCheck] { Array(snapshot.dueToday.prefix(4)) }
    private var doneCount: Int { snapshot.dueToday.filter { $0.loggedToday != nil }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Did I?")
                    .font(Typography.display(17, relativeTo: .headline))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("\(doneCount) of \(snapshot.dueToday.count) today")
                    .font(Typography.text(12, .bold, relativeTo: .caption))
                    .foregroundStyle(Color.tileSun)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.chrome, in: .capsule)
            }
            if checks.isEmpty {
                Text("Add a check in Did I?")
                    .font(.didFootnote)
                    .foregroundStyle(Color.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(checks) { check in
                        Button(intent: WidgetLogIntent(checkID: check.id, source: .homeScreenWidget)) {
                            MiniTile(check: check)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .containerBackground(for: .widget) { Color.ground }
    }
}

private struct MiniTile: View {
    let check: WidgetCheck

    var body: some View {
        let isDone = check.loggedToday != nil
        HStack(spacing: 8) {
            Image(systemName: check.kind.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 26, height: 26)
                .background(isDone ? check.swatch.chip : check.swatch.background, in: .circle)
                .foregroundStyle(check.swatch.foreground)
            VStack(alignment: .leading, spacing: 0) {
                Text(check.name)
                    .font(Typography.display(13, .bold, relativeTo: .footnote))
                    .lineLimit(1)
                if let logged = check.loggedToday {
                    Text(logged, style: .time).font(Typography.text(11, .semibold, relativeTo: .caption2))
                } else {
                    Text("Tap to log").font(Typography.text(11, .semibold, relativeTo: .caption2))
                }
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(isDone ? check.swatch.foreground : Color.ink)
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
        .background {
            let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
            if isDone {
                shape.fill(check.swatch.background)
            } else {
                shape.strokeBorder(Color.ink, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
        }
    }
}

#if DEBUG
#Preview("Medium", as: .systemMedium) {
    ChecksOverviewWidget()
} timeline: {
    OverviewEntry(date: .now, snapshot: .placeholder)
}
#endif
