import AppIntents
import SwiftUI
import WidgetKit

/// The Did I? control for Control Center and the Action Button: logs the check from Settings › Action Button.
struct LogCheckControl: ControlWidget {
    static let kind = "LogCheckControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: ControlPressIntent()) {
                Label("Log a check", systemImage: "checkmark.circle.fill")
            }
        }
        .displayName("Did I? · Log a check")
        .description("Logs the check you picked in Did I? › Settings › Action Button, or asks which.")
    }
}
