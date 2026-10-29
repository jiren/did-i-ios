import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Bindable var settings: AppSettings
    let onOpenActionButton: () -> Void
    let onOpenReminders: () -> Void

    @State private var isConfirmingDelete = false

    init(
        viewModel: @autoclosure () -> SettingsViewModel,
        settings: AppSettings,
        onOpenActionButton: @escaping () -> Void,
        onOpenReminders: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel())
        self.settings = settings
        self.onOpenActionButton = onOpenActionButton
        self.onOpenReminders = onOpenReminders
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(backTitle: String(localized: "Today"), title: String(localized: "Settings"))
                group(String(localized: "Appearance")) {
                    Picker(String(localized: "Appearance"), selection: $settings.appearance) {
                        ForEach(Appearance.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(12)
                    .accessibilityIdentifier("settings.appearance")
                }
                group(String(localized: "Today"), footer: String(localized: "Logs before this count for the day before, so a door checked at 1 AM still counts for last night.")) {
                    SettingsRow(title: String(localized: "Day starts at")) {
                        Picker(String(localized: "Day starts at"), selection: $settings.dayStartHour) {
                            ForEach(0...DayBoundary.latestStartHour, id: \.self) { Text(Self.hourTitle($0)).tag($0) }
                        }
                        .labelsHidden()
                        .accessibilityIdentifier("settings.dayStart")
                    }
                }
                group(String(localized: "Logging")) {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        navigationRow(String(localized: "Action Button"), subtitle: actionButtonSubtitle, action: onOpenActionButton)
                            .accessibilityIdentifier("settings.actionButton")
                        Divider().overlay(Color.line).padding(.leading, 16)
                    }
                    navigationRow(String(localized: "Reminders"), subtitle: String(localized: "Home location and nudges"), action: onOpenReminders)
                        .accessibilityIdentifier("settings.reminders")
                }
                group(String(localized: "Privacy"), footer: String(localized: "Logs stay as long as you keep them; only their photos go.")) {
                    SettingsRow(title: String(localized: "Hide names on Lock Screen"), subtitle: String(localized: "Widgets show only the icon and time")) {
                        Toggle(String(localized: "Hide names on Lock Screen"), isOn: $settings.hidesNamesOnLockScreen)
                            .labelsHidden()
                            .tint(Color.tileViolet)
                    }
                    Divider().overlay(Color.line).padding(.leading, 16)
                    SettingsRow(title: String(localized: "Keep photos")) {
                        Picker(String(localized: "Keep photos"), selection: $settings.keepPhotos) {
                            ForEach(KeepPhotos.allCases) { Text($0.title).tag($0) }
                        }
                        .labelsHidden()
                    }
                }
                group(String(localized: "Data"), footer: viewModel.message) {
                    Button(role: .destructive) { isConfirmingDelete = true } label: {
                        SettingsRow(title: String(localized: "Delete logs and photos")) {
                            Image(systemName: "trash").foregroundStyle(.red)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.delete")
                }
                group(String(localized: "About")) {
                    SettingsRow(title: String(localized: "Did I?"), subtitle: SettingsViewModel.versionText) { EmptyView() }
                    Divider().overlay(Color.line).padding(.leading, 16)
                    Text("Your checks, logs and photos stay on this device. Bricolage Grotesque and DM Sans are used under the SIL Open Font License.")
                        .font(.didFootnoteRegular)
                        .foregroundStyle(Color.muted)
                        .padding(16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.ground)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .task { viewModel.load() }
        .confirmationDialog(String(localized: "Delete your data?"), isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button(String(localized: "Delete logs and photos"), role: .destructive, action: viewModel.deleteAllLogs)
            Button(String(localized: "Delete everything, checks too"), role: .destructive, action: viewModel.deleteEverything)
        } message: {
            Text("This can’t be undone.")
        }
    }

    private var actionButtonSubtitle: String {
        guard let id = settings.actionButtonCheckID, let check = viewModel.checks.first(where: { $0.id == id }) else {
            return String(localized: "Ask me which")
        }
        return check.name
    }

    static func hourTitle(_ hour: Int) -> String {
        hour == 0 ? String(localized: "Midnight") : String(localized: "\(hour) AM")
    }

    private func group<Content: View>(_ title: String, footer: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title: title)
            SettingsCard { content() }
            if let footer {
                Text(footer)
                    .font(.didFootnoteRegular)
                    .foregroundStyle(Color.muted)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func navigationRow(_ title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SettingsRow(title: title, subtitle: subtitle) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.muted)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
