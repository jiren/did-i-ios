import SwiftUI

/// A day in Today's 7-day strip (`Main.dc.html`): weekday, date and dots for the extra categories due.
struct DayStripCell: View {
    let day: DayAgenda.StripDay
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(day.weekdayText)
                    .font(.didMicro)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(day.dayNumber, format: .number)
                    .font(.didStripDay)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(numberColour)
                HStack(spacing: 3) {
                    ForEach(Array(day.dots.enumerated()), id: \.offset) { _, dot in
                        Circle()
                            .fill(day.isSelected ? Color.onSelection : dot.background)
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .foregroundStyle(day.isSelected ? Color.onSelection : Color.ink)
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(day.isSelected ? Color.selection : Color.surface, in: .rect(cornerRadius: 18, style: .continuous))
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(TilePressStyle())
        .accessibilityLabel(day.accessibilityLabel)
        .accessibilityAddTraits(day.isSelected ? .isSelected : [])
    }

    private var numberColour: Color {
        if day.isSelected { return .selectionAccent }
        return day.isToday ? .linkText : .ink
    }
}
