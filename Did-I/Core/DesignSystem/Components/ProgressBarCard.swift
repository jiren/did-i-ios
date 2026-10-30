import SwiftUI

/// Today's sticky progress card (`Main.dc.html`): one line of scope, "4 of 6 done" and the pill, then one segment
/// per task. Mint once all clear.
struct ProgressBarCard: View {
    let progress: DayAgenda.Progress
    /// Today's tasks can be logged, so the pill is ink and sun; a later day's is sand.
    let isToday: Bool
    /// Pinned under the top while scrolling: adds a shadow.
    var isStuck = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { scope; main; Spacer(minLength: 0); pill }
                VStack(alignment: .leading, spacing: 6) { scope; main; pill }
            }
            .padding(.horizontal, 4)
            if !progress.segments.isEmpty {
                segments.padding(.horizontal, 4)
            }
        }
        .padding(EdgeInsets(top: 10, leading: 8, bottom: 8, trailing: 8))
        .foregroundStyle(progress.isAllClear ? Color.onTile : Color.ink)
        .background(progress.isAllClear ? Color.tileMint : Color.surface, in: .rect(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(isStuck ? 0.14 : 0), radius: 9, y: 6)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isStuck)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(progress.scope), \(progress.main), \(progress.pill.text)")
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var scope: some View {
        Text(progress.scope.uppercased())
            .font(.didMicro)
            .tracking(0.5)
            .lineLimit(1)
            .foregroundStyle(progress.isAllClear ? Color.tileMintSub : Color.muted)
    }

    private var main: some View {
        Text(progress.main)
            .font(.didBarTitle)
            .lineLimit(1)
    }

    private var pill: some View {
        HStack(spacing: 5) {
            if progress.isAllClear {
                Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy))
            }
            Text(progress.pill.text).font(.didPill)
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 28)
        .foregroundStyle(pillForeground)
        .background(pillBackground, in: .capsule)
        .fixedSize()
    }

    private var segments: some View {
        HStack(spacing: 3) {
            ForEach(progress.segments) { tile in
                Capsule()
                    .fill(tile.isDone ? tile.swatch.background : Color.ink.opacity(0.12))
                    .frame(height: 5)
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
