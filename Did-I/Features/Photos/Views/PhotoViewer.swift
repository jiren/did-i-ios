import SwiftUI
import UIKit

/// A proof photo full screen, with when it was taken.
struct PhotoViewer: View {
    let image: UIImage?
    let caption: String

    @Environment(\.dismiss) private var dismiss
    @State private var zoom: CGFloat = 1

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(zoom)
                    .gesture(MagnifyGesture().onChanged { zoom = min(max($0.magnification, 1), 4) }.onEnded { _ in
                        withAnimation(.snappy) { zoom = 1 }
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(String(localized: "Proof photo, \(caption)"))
            } else {
                Text("This photo is no longer kept.")
                    .font(.didBody)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            HStack {
                Text(caption)
                    .font(.didEmphasis)
                    .foregroundStyle(.white)
                Spacer()
                RoundIconButton(systemName: "xmark", label: String(localized: "Close"), style: .onColor) { dismiss() }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}
