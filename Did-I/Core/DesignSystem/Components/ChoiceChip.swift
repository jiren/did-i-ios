import SwiftUI

/// A toggleable capsule, as in the Add checks sheet.
struct ChoiceChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .heavy))
                }
                Text(title)
                    .font(.didEmphasis)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .foregroundStyle(isOn ? Color.ground : Color.ink)
            .background(isOn ? Color.ink : Color.clear, in: .capsule)
            .overlay(Capsule().strokeBorder(Color.ink, lineWidth: 2))
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
