import SwiftUI
import UIKit

/// Takes a proof photo: the camera when allowed, an explanation when not.
struct PhotoCaptureView: View {
    let checkName: String
    let onCapture: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var status: CameraAccess.Status?

    var body: some View {
        Group {
            switch status {
            case .authorized:
                CameraPicker(onImage: finish, onCancel: { dismiss() })
                    .ignoresSafeArea()
            case .denied:
                message(
                    title: String(localized: "Camera access is off"),
                    body: String(localized: "Turn it on in Settings to add proof photos. Logging works without one."),
                    actionTitle: String(localized: "Open Settings")
                ) {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            case .unavailable:
                unavailable
            case nil:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.ground)
            }
        }
        .task { status = await CameraAccess.requestIfNeeded() }
    }

    @ViewBuilder
    private var unavailable: some View {
        #if DEBUG
        message(
            title: String(localized: "No camera here"),
            body: String(localized: "This device has no camera. Use a sample photo to try the flow."),
            actionTitle: String(localized: "Use a sample photo")
        ) {
            finish(SamplePhoto.make(caption: checkName))
        }
        #else
        message(
            title: String(localized: "No camera here"),
            body: String(localized: "This device has no camera, so proof photos aren’t available. Logging still works."),
            actionTitle: nil,
            action: {}
        )
        #endif
    }

    private func finish(_ image: UIImage) {
        onCapture(image)
        dismiss()
    }

    private func message(title: String, body: String, actionTitle: String?, action: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.lavender)
                .frame(width: 76, height: 76)
                .background(Color.brandDeep, in: .circle)
                .accessibilityHidden(true)
            Text(title)
                .font(.didSection)
                .foregroundStyle(Color.ink)
            Text(body)
                .font(.didBody)
                .foregroundStyle(Color.muted)
                .multilineTextAlignment(.center)
            if let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(PillButtonStyle(variant: .brand))
                    .accessibilityIdentifier("photo.action")
            }
            Button(String(localized: "Not now")) { dismiss() }
                .font(.didEmphasis)
                .foregroundStyle(Color.linkText)
                .frame(minHeight: 44)
        }
        .padding(32)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ground)
    }
}

#if DEBUG
/// A stand-in proof photo for the Simulator.
enum SamplePhoto {
    static func make(caption: String) -> UIImage {
        let size = CGSize(width: 1200, height: 900)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.16, green: 0.09, blue: 0.44, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let text = "[Photo · \(caption)]" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 64, weight: .bold),
                .foregroundColor: UIColor(red: 0.89, green: 0.85, blue: 1, alpha: 1),
            ]
            let textSize = text.size(withAttributes: attributes)
            text.draw(at: CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2),
                      withAttributes: attributes)
        }
    }
}
#endif
