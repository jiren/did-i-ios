import Charts
import SwiftUI

/// Tasks logged per period: tap a bar, or hold and drag across them, to read it. The chosen bar is ink.
struct StatsBarChart: View {
    let bars: [StatsReport.Bar]
    /// A bar's share of its slot.
    let barRatio: Double
    let selectedID: String?
    let onSelect: (String) -> Void

    var body: some View {
        Chart {
            ForEach([50, 100], id: \.self) { line in
                RuleMark(y: .value("Guide", line))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(Color.gridLine)
                    .accessibilityHidden(true)
            }
            RuleMark(y: .value("Baseline", 0))
                .lineStyle(StrokeStyle(lineWidth: 1))
                .foregroundStyle(Color.line)
                .accessibilityHidden(true)
            ForEach(bars) { bar in
                BarMark(
                    x: .value("Period", bar.id),
                    y: .value("Logged", bar.percent ?? 0),
                    width: .ratio(barRatio)
                )
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4))
                .foregroundStyle(bar.id == selectedID ? Color.ink : Color.tileViolet)
                .accessibilityLabel(bar.detail)
                .accessibilityValue(bar.valueText)
            }
        }
        .chartXScale(domain: bars.map(\.id))
        .chartYScale(domain: 0...100)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { value in
                if let id = value.as(String.self), let bar = bars.first(where: { $0.id == id }) {
                    AxisValueLabel(collisionResolution: .disabled) {
                        Text(bar.label)
                            .font(.didStripWeekday)
                            .foregroundStyle(bar.id == selectedID ? Color.ink : Color.muted)
                            // Past this they collide; the tip above and VoiceOver read each bar at full size.
                            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                    }
                }
            }
        }
        .chartGesture { proxy in
            SpatialTapGesture()
                .onEnded { select(at: $0.location.x, proxy: proxy) }
                .simultaneously(with: LongPressGesture(minimumDuration: 0.2)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onChanged { value in
                        if case .second(true, let drag?) = value { select(at: drag.location.x, proxy: proxy) }
                    }
                )
        }
        .frame(height: Self.height)
        .accessibilityIdentifier("stats.chart")
    }

    /// The design's 120 pt plot and its labels.
    private static let height: CGFloat = 148

    private func select(at x: CGFloat, proxy: ChartProxy) {
        guard let id: String = proxy.value(atX: x, as: String.self) else { return }
        onSelect(id)
    }
}
