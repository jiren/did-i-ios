import SwiftUI

/// "Door locked." after an Action Button press (`Logged.dc.html`).
struct LoggedView: View {
    @State private var viewModel: LoggedViewModel
    let strongHaptic: Bool
    @State private var isTakingPhoto = false
    @State private var hapticTrigger = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: @autoclosure () -> LoggedViewModel, strongHaptic: Bool) {
        _viewModel = State(initialValue: viewModel())
        self.strongHaptic = strongHaptic
    }

    var body: some View {
        VStack(spacing: 0) {
            Label(viewModel.sourceText, systemImage: "button.vertical.right.press")
                .font(.didPill)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.onTile.opacity(0.35), in: .capsule)
            Spacer(minLength: 40)
            badge
            Text(viewModel.title)
                .font(.didLoggedTitle)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
                .accessibilityAddTraits(.isHeader)
            Text(viewModel.whenText)
                .font(Typography.text(20, .semibold, relativeTo: .title3))
                .foregroundStyle(Color.tileVioletSub)
                .padding(.top, 12)
            Spacer(minLength: 40)
            buttons
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tileViolet.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: hapticTrigger)
        .task {
            viewModel.load()
            if strongHaptic { hapticTrigger.toggle() }
            if viewModel.request.opensCamera && !viewModel.hasPhoto { isTakingPhoto = true }
        }
        .onChange(of: viewModel.isUndone) { _, undone in if undone { dismiss() } }
        .fullScreenCover(isPresented: $isTakingPhoto) {
            PhotoCaptureView(checkName: viewModel.checkName) { viewModel.attachPhoto($0) }
        }
    }

    private var badge: some View {
        ZStack {
            Circle().strokeBorder(.white.opacity(0.25), lineWidth: 3).frame(width: 220, height: 220)
            Circle().strokeBorder(.white.opacity(0.45), lineWidth: 3).frame(width: 176, height: 176)
            Image(systemName: "checkmark")
                .font(.system(size: 60, weight: .heavy))
                .foregroundStyle(Color.onTile)
                .frame(width: 132, height: 132)
                .background(Color.tileSun, in: .circle)
        }
        .accessibilityElement()
        .accessibilityLabel("Checked")
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            Button { isTakingPhoto = true } label: {
                Label(viewModel.hasPhoto ? String(localized: "Retake the photo") : String(localized: "Add a photo as proof"),
                      systemImage: "camera.fill")
            }
            .buttonStyle(PillButtonStyle(variant: .light))
            HStack(spacing: 12) {
                Button(String(localized: "Undo"), action: viewModel.undo)
                    .buttonStyle(PillButtonStyle(variant: .outline, height: 56))
                    .accessibilityIdentifier("logged.undo")
                Button(String(localized: "Done")) { dismiss() }
                    .buttonStyle(PillButtonStyle(variant: .ink, height: 56))
                    .accessibilityIdentifier("logged.done")
            }
        }
    }
}
