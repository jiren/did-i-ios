import SwiftUI

/// "3 of 4 today", sun on ink.
struct ProgressPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.didPill)
            .foregroundStyle(Color.tileSun)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.chrome, in: .capsule)
    }
}
