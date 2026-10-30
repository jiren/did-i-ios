import SwiftUI

/// "Today  Fri, Oct 30" (or "Sat  Oct 31"), then the grid/list toggle, Categories and Settings (`Main.dc.html`).
struct TodayHeader: View {
    let dayTitle: String
    let daySub: String
    let layout: TodayLayout
    let onToggleLayout: () -> Void
    let onCategories: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) { title; sub }
                VStack(alignment: .leading, spacing: 0) { title; sub }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("today.date")
            RoundIconButton(
                systemName: layout == .grid ? "list.bullet" : "square.grid.2x2",
                label: layout == .grid ? String(localized: "Show as list") : String(localized: "Show as grid"),
                style: .surface,
                action: onToggleLayout
            )
            .accessibilityIdentifier("today.layout")
            RoundIconButton(systemName: "rectangle.stack.fill", label: String(localized: "Categories"), action: onCategories)
                .accessibilityIdentifier("today.categories")
            RoundIconButton(systemName: "gearshape.fill", label: String(localized: "Settings"), action: onSettings)
                .accessibilityIdentifier("today.settings")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var title: some View {
        Text(dayTitle).font(.didDayTitle).foregroundStyle(Color.ink).lineLimit(1)
    }

    private var sub: some View {
        Text(daySub).font(.didSubheadline).foregroundStyle(Color.muted).lineLimit(1)
    }
}
