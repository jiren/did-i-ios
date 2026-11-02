import SwiftUI

enum MainTab: Hashable {
    case today, stats, history
}

/// The floating bar: Today, Stats, History and the round Add button, on Liquid Glass tinted ink.
struct FloatingTabBar: View {
    @Binding var selection: MainTab
    /// Today's due tasks done, 0 to 1, for the ring on the Today tab; nil hides the ring.
    var todayProgress: Double?
    /// "Today: 4 of 8 checked".
    var todayAccessibilityLabel: String?
    /// Every tap on Today, including when it's already selected (Today goes back to today).
    var onSelectToday: (() -> Void)?
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            item(.today, title: String(localized: "Today"))
            item(.stats, title: String(localized: "Stats"))
            item(.history, title: String(localized: "History"))
            Spacer(minLength: 0)
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.tileViolet, in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add tasks")
            .accessibilityIdentifier("tabbar.add")
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 68)
        .glassEffect(.regular.tint(Color.chrome), in: .capsule)
    }

    private func item(_ tab: MainTab, title: String) -> some View {
        let isSelected = selection == tab
        return Button {
            selection = tab
            if tab == .today { onSelectToday?() }
        } label: {
            HStack(spacing: 8) {
                if tab == .today, let todayProgress {
                    ProgressRing(fraction: todayProgress, colour: isSelected ? .onTile : .onChromeMuted)
                }
                Text(title)
                    .font(isSelected ? .didEmphasis : .didSubheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(isSelected ? Color.onTile : Color.onChromeMuted)
            .padding(.leading, isSelected && !(tab == .today && todayProgress != nil) ? 18 : 12)
            .padding(.trailing, isSelected ? 18 : 12)
            .frame(minHeight: 48)
            .background(isSelected ? Color.tileSun : Color.clear, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(tab == .today ? todayAccessibilityLabel ?? title : title)
        .accessibilityIdentifier(identifier(for: tab))
    }

    private func identifier(for tab: MainTab) -> String {
        switch tab {
        case .today: "tabbar.today"
        case .stats: "tabbar.stats"
        case .history: "tabbar.history"
        }
    }
}
