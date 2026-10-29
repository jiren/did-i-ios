import AppIntents
import SwiftUI
import WidgetKit

/// Which check a single-check widget shows.
struct SelectCheckIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose a Check"
    static let description = IntentDescription("The check this widget shows and logs.")

    @Parameter(title: "Check")
    var check: CheckEntity?

    init() {}
}

struct CheckEntry: TimelineEntry {
    let date: Date
    let check: WidgetCheck?
    let hidesNames: Bool
}

struct CheckTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CheckEntry {
        CheckEntry(date: Date(), check: WidgetSnapshot.placeholder.checks.first, hidesNames: false)
    }

    func snapshot(for configuration: SelectCheckIntent, in context: Context) async -> CheckEntry {
        context.isPreview ? placeholder(in: context) : entry(for: configuration, at: Date()).entry
    }

    func timeline(for configuration: SelectCheckIntent, in context: Context) async -> Timeline<CheckEntry> {
        let now = Date()
        let (current, nextDayStart) = entry(for: configuration, at: now)
        let tomorrow = CheckEntry(
            date: nextDayStart,
            check: current.check.map { WidgetCheck(id: $0.id, name: $0.name, kind: $0.kind, swatch: $0.swatch, loggedToday: nil) },
            hidesNames: current.hidesNames
        )
        return Timeline(entries: [current, tomorrow], policy: .after(nextDayStart))
    }

    @MainActor
    private func entry(for configuration: SelectCheckIntent, at now: Date) -> (entry: CheckEntry, nextDayStart: Date) {
        let snapshot = WidgetSnapshot.read(services: IntentServices.shared, now: now)
        let check = snapshot.checks.first { $0.id == configuration.check?.id } ?? snapshot.checks.first
        return (CheckEntry(date: now, check: check, hidesNames: snapshot.hidesNames), snapshot.nextDayStart)
    }
}

/// One check on the Lock Screen (circular, rectangular) or Home Screen (small); a tap logs it.
struct CheckWidget: Widget {
    static let kind = "CheckWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: SelectCheckIntent.self, provider: CheckTimelineProvider()) { entry in
            CheckWidgetView(entry: entry)
        }
        .configurationDisplayName("Did I?")
        .description("See when you last did it, and log it with a tap.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}

struct CheckWidgetView: View {
    let entry: CheckEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let check = entry.check {
            Button(intent: WidgetLogIntent(checkID: check.id, source: family == .systemSmall ? .homeScreenWidget : .lockScreenWidget)) {
                content(check)
            }
            .buttonStyle(.plain)
        } else {
            Text("Add a check in Did I?")
                .font(.didFootnote)
                .containerBackground(for: .widget) { Color.ground }
        }
    }

    @ViewBuilder
    private func content(_ check: WidgetCheck) -> some View {
        switch family {
        case .accessoryCircular:
            CircularCheckView(check: check)
        case .accessoryRectangular:
            RectangularCheckView(check: check, hidesName: entry.hidesNames)
        default:
            SmallCheckView(check: check)
        }
    }
}

struct CircularCheckView: View {
    let check: WidgetCheck

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: check.kind.symbolName)
                    .font(.system(size: 20, weight: .semibold))
                    .widgetAccentable()
                if let logged = check.loggedToday {
                    Text(logged, format: .dateTime.hour(.defaultDigits(amPM: .omitted)).minute())
                        .font(Typography.text(12, .bold, relativeTo: .caption))
                } else {
                    Text("Tap")
                        .font(Typography.text(12, .bold, relativeTo: .caption))
                }
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard let logged = check.loggedToday else { return String(localized: "\(check.name): not logged today. Tap to log.") }
        return String(localized: "\(check.name): logged at \(logged.formatted(date: .omitted, time: .shortened)). Tap to log again.")
    }
}

struct RectangularCheckView: View {
    let check: WidgetCheck
    let hidesName: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("DID I?", systemImage: "checkmark")
                .font(Typography.text(12, .bold, relativeTo: .caption))
                .labelStyle(.titleAndIcon)
                .widgetAccentable()
            Text(hidesName ? check.kind.title : check.name)
                .font(Typography.display(17, .bold, relativeTo: .headline))
                .lineLimit(1)
                .privacySensitive()
            if let logged = check.loggedToday {
                Text("\(logged, style: .time) · \(logged, style: .relative)")
                    .font(Typography.text(13, .semibold, relativeTo: .footnote))
                    .lineLimit(1)
            } else {
                Text("Not yet today · tap to log")
                    .font(Typography.text(13, .semibold, relativeTo: .footnote))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }
}

/// A Home Screen tile in the check's colour, like Today's.
struct SmallCheckView: View {
    let check: WidgetCheck

    var body: some View {
        let isDone = check.loggedToday != nil
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                TileIcon(kind: check.kind, swatch: check.swatch, isDone: isDone)
                Spacer()
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Color.onTile, in: .circle)
                }
            }
            Spacer(minLength: 6)
            Text(check.name)
                .font(Typography.display(17, .bold, relativeTo: .headline))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            if let logged = check.loggedToday {
                Text(logged, style: .time)
                    .font(Typography.text(17, .bold, relativeTo: .headline))
                Text(logged, style: .relative)
                    .font(Typography.text(12, .semibold, relativeTo: .caption))
                    .foregroundStyle(check.swatch.secondary)
            } else {
                Text("Tap to log")
                    .font(Typography.text(17, .bold, relativeTo: .headline))
                Text("Not yet today")
                    .font(Typography.text(12, .semibold, relativeTo: .caption))
                    .foregroundStyle(Color.muted)
            }
        }
        .foregroundStyle(isDone ? check.swatch.foreground : Color.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            if isDone { check.swatch.background } else { Color.ground }
        }
    }
}

#if DEBUG
#Preview("Circular", as: .accessoryCircular) {
    CheckWidget()
} timeline: {
    CheckEntry(date: .now, check: WidgetSnapshot.placeholder.checks[0], hidesNames: false)
    CheckEntry(date: .now, check: WidgetSnapshot.placeholder.checks[2], hidesNames: false)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    CheckWidget()
} timeline: {
    CheckEntry(date: .now, check: WidgetSnapshot.placeholder.checks[0], hidesNames: false)
    CheckEntry(date: .now, check: WidgetSnapshot.placeholder.checks[1], hidesNames: true)
}

#Preview("Small", as: .systemSmall) {
    CheckWidget()
} timeline: {
    CheckEntry(date: .now, check: WidgetSnapshot.placeholder.checks[0], hidesNames: false)
    CheckEntry(date: .now, check: WidgetSnapshot.placeholder.checks[3], hidesNames: false)
}
#endif
