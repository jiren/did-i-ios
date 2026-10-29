import SwiftUI

/// Shown if the store can't be opened, instead of crashing.
struct LaunchFailureView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Text("Did I? couldn’t open your checks")
                .font(.didSection)
                .foregroundStyle(Color.ink)
            Text(message)
                .font(.didFootnoteRegular)
                .foregroundStyle(Color.muted)
        }
        .multilineTextAlignment(.center)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ground)
    }
}
