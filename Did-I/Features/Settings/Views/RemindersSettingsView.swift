import SwiftUI

struct RemindersSettingsView: View {
    @State private var viewModel: RemindersSettingsViewModel
    @Environment(\.openURL) private var openURL

    init(viewModel: @autoclosure () -> RemindersSettingsViewModel) {
        _viewModel = State(initialValue: viewModel())
    }

    var body: some View {
        @Bindable var settings = viewModel.settings
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(
                    backTitle: String(localized: "Settings"),
                    title: String(localized: "Reminders"),
                    subtitle: String(localized: "A nudge only when something isn’t logged yet.")
                )
                section(String(localized: "Notifications")) {
                    SettingsRow(title: String(localized: "Notifications"), subtitle: notificationSubtitle) {
                        switch viewModel.notificationStatus {
                        case .allowed:
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.tileMint)
                        case .denied:
                            Button(String(localized: "Settings")) {
                                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                            }
                            .font(.didEmphasis)
                        case .notAsked:
                            Button(String(localized: "Allow")) { Task { await viewModel.allowNotifications() } }
                                .font(.didEmphasis)
                        }
                    }
                }
                section(String(localized: "Leaving home"), footer: String(localized: "Checks with “Nudge me when I leave home” on remind you as you leave, if they aren’t logged yet. This needs location access set to Always; your location stays on this device.")) {
                    SettingsRow(
                        title: String(localized: "Home"),
                        subtitle: viewModel.hasHome ? String(localized: "Set · within 150 m") : String(localized: "Not set")
                    ) {
                        if viewModel.isLocating {
                            ProgressView()
                        } else {
                            Button(viewModel.hasHome ? String(localized: "Move here") : String(localized: "Set to here")) {
                                Task { await viewModel.setHomeHere() }
                            }
                            .font(.didEmphasis)
                            .accessibilityIdentifier("reminders.setHome")
                        }
                    }
                    if viewModel.hasHome {
                        Divider().overlay(Color.line).padding(.leading, 16)
                        Button(String(localized: "Forget home"), role: .destructive, action: viewModel.forgetHome)
                            .font(.didRowTitle)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider().overlay(Color.line).padding(.leading, 16)
                    SettingsRow(title: String(localized: "Tell me when I’m good"), subtitle: String(localized: "Also notify for checks already logged")) {
                        Toggle(String(localized: "Tell me when I’m good"), isOn: $settings.reassuresOnLeavingHome)
                            .labelsHidden()
                            .tint(Color.tileViolet)
                    }
                }
                if let message = viewModel.locationMessage {
                    Text(message).font(.didFootnoteRegular).foregroundStyle(Color.muted)
                }
                section(String(localized: "On each check"), footer: String(localized: "Set a reminder time or the leaving-home nudge on a check’s page.")) {
                    let lines = viewModel.reminderLines + viewModel.nudgeNames.map { String(localized: "\($0) · when leaving home") }
                    if lines.isEmpty {
                        SettingsRow(title: String(localized: "None yet")) { EmptyView() }
                    } else {
                        ForEach(lines, id: \.self) { line in
                            SettingsRow(title: line) { EmptyView() }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.ground)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
    }

    private var notificationSubtitle: String {
        switch viewModel.notificationStatus {
        case .allowed: String(localized: "On")
        case .denied: String(localized: "Off. Turn them on in Settings.")
        case .notAsked: String(localized: "Needed for reminders and nudges")
        }
    }

    private func section<Content: View>(_ title: String, footer: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title: title)
            SettingsCard { content() }
            if let footer {
                Text(footer).font(.didFootnoteRegular).foregroundStyle(Color.muted).padding(.horizontal, 4)
            }
        }
    }
}
