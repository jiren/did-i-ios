import SwiftUI

/// "Nothing due" with why, when no category is due on the selected day.
struct NothingDueCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nothing due").font(.didBarTitle)
            Text(text).font(.didCaptionBody).foregroundStyle(Color.muted)
        }
        .foregroundStyle(Color.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.surface, in: .rect(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
