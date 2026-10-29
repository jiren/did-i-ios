import SwiftUI

/// The small uppercase labels above groups ("A PRESS LOGS").
struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.didLabel)
            .tracking(0.6)
            .foregroundStyle(Color.muted)
            .accessibilityAddTraits(.isHeader)
    }
}
