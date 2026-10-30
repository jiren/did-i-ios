import SwiftUI

/// Today's sticky progress card (`Main.dc.html`): scope, "4 of 6 done", the pill and one segment per task. Mint
/// once all clear.
struct ProgressBarCard: View {
    let progress: DayAgenda.Progress
    /// Today's tasks can be logged, so the pill is ink and sun; a later day's is sand.
    let isToday: Bool
    /// Pinned under the top while scrolling: adds a shadow.
    var isStuck = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { titles; Spacer(minLength: 0); pill }
                VStack(alignment: .leading, spacing: 8) { titles; pill }
            }
            if !progress.segments.isEmpty {
                segments
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 12))
        .foregroundStyle(progress.isAllClear ? Color.onTile : Color.ink)
        .background(progress.isAllClear ? Color.tileMint : Color.surface, in: .rect(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(isStuck ? 0.14 : 0), radius: 9, y: 6)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isStuck)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(progress.scope), \(progress.main), \(progress.pill.text)")
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(progress.scope.uppercased())
                .font(.didMicro)
                .tracking(0.6)
                .foregroundStyle(progress.isAllClear ? Color.tileMintSub : Color.muted)
            Text(progress.main)
                .font(.didBarTitle)
        }
    }

    private var pill: some View {
        HStack(spacing: 6) {
            if progress.isAllClear {
                Image(systemName: "checkmark").font(.system(size: 13, weight: .heavy))
            }
            Text(progress.pill.text).font(.didEmphasis)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 36)
        .foregroundStyle(pillForeground)
        .background(pillBackground, in: .capsule)
        .fixedSize()
    }

    private var segments: some View {
        HStack(spacing: 3) {
            ForEach(progress.segments) { tile in
                Capsule()
                    .fill(tile.isDone ? tile.swatch.background : Color.ink.opacity(0.12))
                    .frame(height: 6)
            }
        }
        .accessibilityHidden(true)
    }

    private var pillForeground: Color {
        if progress.isAllClear { return .onChrome }
        return isToday && !progress.segments.isEmpty ? .selectionAccent : .ink
    }

    private var pillBackground: Color {
        if progress.isAllClear { return .chrome }
        return isToday && !progress.segments.isEmpty ? .selection : .sand
    }
}
