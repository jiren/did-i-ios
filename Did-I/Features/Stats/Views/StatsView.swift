import SwiftUI

/// How the logging went, by week, month or year (`Stats.dc.html`).
struct StatsView: View {
    @State private var viewModel: StatsViewModel
    @Binding var tab: MainTab
    let onAddChecks: () -> Void

    @Environment(StoreChangeHub.self) private var changes

    init(viewModel: @autoclosure () -> StatsViewModel, tab: Binding<MainTab>, onAddChecks: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel())
        _tab = tab
        self.onAddChecks = onAddChecks
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                if let message = viewModel.errorMessage {
                    StatsMessageCard(title: message, message: nil)
                } else if let report = viewModel.report {
                    if report.hasLogs {
                        content(report)
                    } else {
                        StatsMessageCard(
                            title: String(localized: "Nothing to show yet"),
                            message: String(localized: "Log a few tasks and your numbers show up here.")
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .background(Color.ground)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            FloatingTabBar(selection: $tab, onAdd: onAddChecks)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .task { viewModel.reload() }
        .onChange(of: changes.version) { viewModel.reload() }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { title; Spacer(minLength: 0); rangePicker }
            VStack(alignment: .leading, spacing: 8) { title; rangePicker }
        }
    }

    private var title: some View {
        Text("Stats")
            .font(.didTabTitle)
            .foregroundStyle(Color.ink)
            .accessibilityAddTraits(.isHeader)
    }

    private var rangePicker: some View {
        StatsRangePicker(selection: viewModel.range, onSelect: viewModel.selectRange)
    }

    @ViewBuilder
    private func content(_ report: StatsReport) -> some View {
        StatsPair {
            StreakCard(days: report.streak)
        } trailing: {
            SecondGuessesCard(trend: report.trend, previousLabel: report.range.previousLabel)
        }
        TasksLoggedCard(
            report: report,
            selectedBar: viewModel.selectedBar,
            onSelect: viewModel.selectBar
        )
        if !report.categories.isEmpty { ByCategoryCard(rows: report.categories) }
        if !report.methods.isEmpty { HowYouLogCard(rows: report.methods) }
        StatsPair {
            MostRecheckedCard(most: report.mostRechecked)
        } trailing: {
            PhotoProofCard(photosKept: report.photosKept, busiestHour: report.busiestHour)
        }
    }
}

/// The Week / Month / Year pills.
private struct StatsRangePicker: View {
    let selection: StatsRange
    let onSelect: (StatsRange) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(StatsRange.allCases) { range in
                let isOn = range == selection
                Button { onSelect(range) } label: {
                    Text(range.title)
                        .font(.didPill)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .foregroundStyle(isOn ? Color.ground : Color.ink)
                        .background(isOn ? Color.ink : Color.clear, in: .capsule)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
                .accessibilityIdentifier("stats.range.\(range.rawValue)")
            }
        }
        .background(Color.ink.opacity(0.06), in: .capsule)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Time range")
    }
}

/// Two cards side by side, or stacked at accessibility text sizes.
private struct StatsPair<Leading: View, Trailing: View>: View {
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: 10) { leading; trailing }
        } else {
            HStack(spacing: 10) { leading; trailing }
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The screen's rounded card.
private struct StatsCard<Content: View>: View {
    var background: Color = .surface
    var padding: CGFloat = 16
    var spacing: CGFloat = 12
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(background, in: .rect(cornerRadius: 22, style: .continuous))
    }
}

private struct StatsMessageCard: View {
    let title: String
    let message: String?

    var body: some View {
        StatsCard(spacing: 4) {
            Text(title)
                .font(.didCardTitle)
                .foregroundStyle(Color.ink)
            if let message {
                Text(message)
                    .font(.didBody)
                    .foregroundStyle(Color.muted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stats.empty")
    }
}

/// An uppercase card label ("STREAK").
private struct StatLabel: View {
    let text: String
    var colour: Color = .muted

    var body: some View {
        Text(text)
            .font(.didMicro)
            .tracking(0.5)
            .foregroundStyle(colour)
    }
}

private struct StreakCard: View {
    let days: Int
    @ScaledMetric(relativeTo: .largeTitle) private var minHeight: CGFloat = 96

    private var caption: String {
        days == 1 ? String(localized: "day with every task logged") : String(localized: "days with every task logged")
    }

    var body: some View {
        StatsCard(background: .tileViolet, padding: 14, spacing: 2) {
            StatLabel(text: String(localized: "STREAK"), colour: .tileVioletSub)
            Spacer(minLength: 8)
            Text(days, format: .number)
                .font(.didStatValue)
                .foregroundStyle(Color.white)
            Text(caption)
                .font(.didFootnote)
                .foregroundStyle(Color.tileVioletSub)
        }
        .frame(minHeight: minHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Streak")
        .accessibilityValue("\(days) \(caption)")
        .accessibilityIdentifier("stats.streak")
    }
}

private struct SecondGuessesCard: View {
    let trend: StatsReport.Trend
    let previousLabel: String
    @ScaledMetric(relativeTo: .largeTitle) private var minHeight: CGFloat = 96

    private var value: String {
        switch trend {
        case .down(let percent), .up(let percent): "\(percent)%"
        case .same: "0%"
        case .noComparison(let count): String(count)
        }
    }

    private var caption: String {
        if case .noComparison = trend { return String(localized: "re-logs within 30 min") }
        return String(localized: "re-logs within 30 min, vs \(previousLabel)")
    }

    private var spokenValue: String {
        switch trend {
        case .down(let percent): String(localized: "down \(percent)%, \(caption)")
        case .up(let percent): String(localized: "up \(percent)%, \(caption)")
        case .same, .noComparison: "\(value), \(caption)"
        }
    }

    var body: some View {
        StatsCard(padding: 14, spacing: 2) {
            StatLabel(text: String(localized: "SECOND-GUESSES"))
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                arrow
                Text(value)
                    .font(.didStatValue)
                    .foregroundStyle(Color.ink)
            }
            Text(caption)
                .font(.didFootnote)
                .foregroundStyle(Color.muted)
        }
        .frame(minHeight: minHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Second-guesses")
        .accessibilityValue(spokenValue)
        .accessibilityIdentifier("stats.secondGuesses")
    }

    @ViewBuilder
    private var arrow: some View {
        switch trend {
        case .down:
            Image(systemName: "arrow.down").font(.system(.title2, weight: .heavy)).foregroundStyle(Color.statMint)
        case .up:
            Image(systemName: "arrow.up").font(.system(.title2, weight: .heavy)).foregroundStyle(Color.statCoral)
        case .same, .noComparison:
            EmptyView()
        }
    }
}

private struct TasksLoggedCard: View {
    let report: StatsReport
    let selectedBar: StatsReport.Bar?
    let onSelect: (String) -> Void

    var body: some View {
        StatsCard {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Tasks logged")
                        .font(.didCardTitle)
                        .foregroundStyle(Color.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Share of due tasks you logged")
                        .font(.didFootnoteRegular)
                        .foregroundStyle(Color.muted)
                }
                Spacer(minLength: 0)
                average
            }
            if let selectedBar {
                Text(selectedBar.tip)
                    .font(.didFootnote)
                    .foregroundStyle(Color.ink)
                    .accessibilityIdentifier("stats.tip")
            }
            StatsBarChart(
                bars: report.bars,
                barRatio: Self.barRatio(report.range),
                selectedID: selectedBar?.id,
                onSelect: onSelect
            )
        }
    }

    private var average: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(report.average.map { "\($0)%" } ?? "–")
                .font(.didDayTitle)
                .foregroundStyle(Color.ink)
            Text("average")
                .font(.didMicro)
                .foregroundStyle(Color.muted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Average")
        .accessibilityValue(report.average.map { "\($0)%" } ?? String(localized: "Nothing due"))
        .accessibilityIdentifier("stats.average")
    }

    /// A bar's share of its slot: the design caps bars at 28 pt, so fewer slots mean narrower shares.
    private static func barRatio(_ range: StatsRange) -> Double {
        switch range {
        case .week: 0.62
        case .month: 0.45
        case .year: 0.9
        }
    }
}

private struct ByCategoryCard: View {
    let rows: [StatsReport.CategoryRow]

    var body: some View {
        StatsCard {
            Text("By category")
                .font(.didCardTitle)
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
            ForEach(rows) { row in
                CategoryStatRow(row: row)
            }
        }
    }
}

private struct CategoryStatRow: View {
    let row: StatsReport.CategoryRow
    @ScaledMetric(relativeTo: .subheadline) private var nameWidth: CGFloat = 96
    @ScaledMetric(relativeTo: .subheadline) private var percentWidth: CGFloat = 40
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) { badge; name; Spacer(minLength: 0); percent }
                    bar
                }
            } else {
                HStack(spacing: 10) {
                    badge
                    name.frame(width: nameWidth, alignment: .leading)
                    bar
                    percent.frame(width: percentWidth, alignment: .trailing)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.category.name)
        .accessibilityValue("\(row.percent)%")
    }

    private var badge: some View {
        CategoryBadge(icon: row.category.icon, colour: row.category.colour, size: 28, cornerRadius: 9)
    }

    private var name: some View {
        Text(row.category.name)
            .font(.didPill)
            .foregroundStyle(Color.ink)
            .lineLimit(1)
    }

    private var percent: some View {
        Text("\(row.percent)%")
            .font(.didPill)
            .foregroundStyle(Color.ink)
    }

    private var bar: some View {
        Capsule()
            .fill(Color.sand)
            .frame(height: 8)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(row.category.colour.background)
                        .frame(width: proxy.size.width * Double(row.percent) / 100)
                }
            }
            .clipShape(.capsule)
    }
}

private struct HowYouLogCard: View {
    let rows: [StatsReport.MethodRow]

    var body: some View {
        StatsCard {
            Text("How you log")
                .font(.didCardTitle)
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
            segments
            VStack(alignment: .leading, spacing: 6) {
                ForEach(rows) { row in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(row.method.colour)
                            .frame(width: 10, height: 10)
                        Text(row.method.label)
                            .font(.didSubheadline)
                            .foregroundStyle(Color.ink)
                        Spacer(minLength: 0)
                        Text("\(row.percent)%")
                            .font(.didPill)
                            .foregroundStyle(Color.ink)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    /// One bar split by share, with a 2 pt gap between methods.
    private var segments: some View {
        GeometryReader { proxy in
            let gaps = CGFloat(max(rows.count - 1, 0)) * 2
            let total = Double(rows.reduce(0) { $0 + $1.count })
            HStack(spacing: 2) {
                ForEach(rows) { row in
                    Rectangle()
                        .fill(row.method.colour)
                        .frame(width: max(proxy.size.width - gaps, 0) * Double(row.count) / max(total, 1))
                }
            }
            .clipShape(.rect(cornerRadius: 4))
        }
        .frame(height: 14)
        .accessibilityHidden(true)
    }
}

private extension StatsReport.Method {
    /// Fixed per method, so a method keeps its colour across ranges.
    var colour: Color {
        switch self {
        case .actionButton: .tileViolet
        case .lockScreenWidget: .statCoral
        case .app: .statMint
        case .homeScreenWidget: .statSky
        case .siriAndShortcuts: .statPink
        case .notification: .statSun
        }
    }
}

private struct MostRecheckedCard: View {
    let most: StatsReport.MostRechecked?

    private var name: String { most?.name ?? String(localized: "None") }

    private var caption: String {
        guard let most else { return String(localized: "No re-logs in this range") }
        return most.count == 1
            ? String(localized: "1 re-log · a photo can settle it")
            : String(localized: "\(most.count) re-logs · a photo can settle it")
    }

    var body: some View {
        StatDetailCard(
            symbol: most?.kind.symbolName ?? "checkmark",
            tint: .tileCoral,
            label: String(localized: "MOST RE-CHECKED"),
            title: name,
            caption: caption
        )
        .accessibilityIdentifier("stats.mostRechecked")
    }
}

private struct PhotoProofCard: View {
    let photosKept: Int
    let busiestHour: String?

    private var title: String {
        photosKept == 1 ? String(localized: "1 photo kept") : String(localized: "\(photosKept) photos kept")
    }

    var body: some View {
        StatDetailCard(
            symbol: "camera.fill",
            tint: .tileSun,
            label: String(localized: "PHOTO PROOF"),
            title: title,
            caption: busiestHour.map { String(localized: "Busiest hour: \($0)") } ?? String(localized: "No logs in this range")
        )
        .accessibilityIdentifier("stats.photos")
    }
}

/// The bottom pair's card: an icon, a label, a line and a caption.
private struct StatDetailCard: View {
    let symbol: String
    let tint: Color
    let label: String
    let title: String
    let caption: String

    var body: some View {
        StatsCard(padding: 14, spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.onTile)
                .frame(width: 32, height: 32)
                .background(tint, in: .rect(cornerRadius: 11, style: .continuous))
                .accessibilityHidden(true)
            StatLabel(text: label)
                .padding(.top, 6)
            Text(title)
                .font(.didRowTitle)
                .foregroundStyle(Color.ink)
            Text(caption)
                .font(.didFootnoteRegular)
                .foregroundStyle(Color.muted)
        }
        .accessibilityElement(children: .combine)
    }
}
