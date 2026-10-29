import SwiftUI

/// A new install's Today: no checks yet.
struct TodayEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.tileViolet)
                .accessibilityHidden(true)
            Text("Nothing to check yet")
                .font(.didSection)
                .foregroundStyle(Color.ink)
            Text("Add the things you double-check — the front door, the stove, a pill. Then one tap each time, and you’ll never have to wonder.")
                .font(.didBody)
                .foregroundStyle(Color.muted)
            Button("Add checks", action: onAdd)
                .buttonStyle(PillButtonStyle(variant: .brand))
                .padding(.top, 4)
                .accessibilityIdentifier("today.empty.add")
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: .rect(cornerRadius: 28, style: .continuous))
    }
}
