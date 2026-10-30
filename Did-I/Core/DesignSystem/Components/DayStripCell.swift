import SwiftUI

/// A day in Today's 7-day strip (`Main.dc.html`): its letter (or "Today"), the date, and dots for the extra
/// categories due.
struct DayStripCell: View {
    let day: DayAgenda.StripDay
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(day.weekdayText)
                    .font(.didStripWeekday)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(day.isSelected ? Color.onSelection : Color.muted)
                Text(day.dayNumber, format: .number)
                    .font(.didStripDay)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(numberColour)
                HStack(spacing: 3) {
                    ForEach(Array(day.dots.enumerated()), id: \.offset) { _, dot in
                        Circle()
                            .fill(day.isSelected ? Color.onSelection : dot.background)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(day.isSelected ? Color.selection : Color.surface, in: .rect(cornerRadius: 16, style: .continuous))
            .contentShape(.rect(cornerRadius: 16))
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
