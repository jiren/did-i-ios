#if DEBUG
import SwiftUI

/// Every design-system component, for checking both themes and text sizes. Launch with `-Gallery`.
struct ComponentGallery: View {
    /// Starts scrolled to the controls, for screenshots.
    var startsAtControls = false
    @State private var chipOn = true
    @State private var switchOn = true
    @State private var tab: MainTab = .today

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !startsAtControls { tilesSection }
                controlsSection
            }
            .padding(20)
        }
        .background(Color.ground)
    }

    @ViewBuilder
    private var tilesSection: some View {
                Text("Did I?").font(.didHero).foregroundStyle(Color.ink)
                HStack {
                    ProgressPill(text: "3 of 4 today")
                    Text("1 left: Iron unplugged").font(.didEmphasis).foregroundStyle(Color.ink)
                }
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(sampleTiles.enumerated()), id: \.offset) { _, content in
                        CheckTile(content: content, onLog: {}, onPhoto: {})
                    }
                    AddTile {}
                }
    }

    @ViewBuilder
    private var controlsSection: some View {
                SectionLabel(title: "A press logs")
                FlowLayout(spacing: 8) {
                    ChoiceChip(title: "Windows closed", isOn: chipOn) { chipOn.toggle() }
                    ChoiceChip(title: "Car locked", isOn: !chipOn) { chipOn.toggle() }
                }
                SwitchRow(title: "Nudge me when I leave home", subtitle: "Only if it isn’t logged yet",
                          symbolName: "bell.fill", isOn: $switchOn)
                HStack {
                    RoundIconButton(systemName: "gearshape.fill", label: "Settings") {}
                    RoundIconButton(systemName: "xmark", label: "Close", style: .sand) {}
                    RoundIconButton(systemName: "chevron.left", label: "Back", style: .onColor) {}
                        .padding(6).background(Color.tileViolet, in: .capsule)
                }
                VStack(spacing: 0) {
                    TimelineRow(title: "Today, 8:42 AM", subtitle: "Action Button · photo", isNewest: true, isLast: false)
                    TimelineRow(title: "Yesterday, 10:58 PM", subtitle: "Lock Screen widget", isNewest: false, isLast: true)
                }
                Button("Log it again") {}.buttonStyle(PillButtonStyle())
                Button("Add 2 checks") {}.buttonStyle(PillButtonStyle(variant: .brand))
                Button("Pick at least one") {}.buttonStyle(PillButtonStyle(variant: .brand)).disabled(true)
                UndoToast(message: "Logged · Front door locked") {}
                FloatingTabBar(selection: $tab) {}
    }

    private var sampleTiles: [CheckTileContent] {
        [
            CheckTileContent(name: "Front door locked", kind: .door, swatch: .violet, isDone: true, hasPhoto: true,
                             timeText: "8:42 AM", detailText: "2h 9m ago · photo", accessibilityLabel: "", photoButtonLabel: ""),
            CheckTileContent(name: "Pill taken", kind: .pill, swatch: .sun, isDone: true, hasPhoto: false,
                             timeText: "8:15 AM", detailText: "2h 27m ago", accessibilityLabel: "", photoButtonLabel: ""),
            CheckTileContent(name: "Stove off", kind: .stove, swatch: .coral, isDone: true, hasPhoto: false,
                             timeText: "8:30 AM", detailText: "2h 12m ago", accessibilityLabel: "", photoButtonLabel: ""),
            CheckTileContent(name: "Iron unplugged", kind: .plug, swatch: .mint, isDone: false, hasPhoto: false,
                             timeText: "Tap to log", detailText: "Not yet today", accessibilityLabel: "", photoButtonLabel: ""),
            CheckTileContent(name: "Lights off", kind: .light, swatch: .sky, isDone: true, hasPhoto: false,
                             timeText: "9:02 AM", detailText: "1h 40m ago", accessibilityLabel: "", photoButtonLabel: ""),
            CheckTileContent(name: "Cat fed", kind: .other, swatch: .pink, isDone: true, hasPhoto: false,
                             timeText: "7:50 AM", detailText: "2h 52m ago", accessibilityLabel: "", photoButtonLabel: ""),
        ]
    }
}

#Preview("Light") { ComponentGallery().preferredColorScheme(.light) }
#Preview("Dark") { ComponentGallery().preferredColorScheme(.dark) }
#Preview("AX") { ComponentGallery().dynamicTypeSize(.accessibility2) }
#endif
