import SwiftUI
import WidgetKit

@main
struct DidIWidgetsBundle: WidgetBundle {
    init() {
        FontRegistration.registerBundledFonts()
    }

    var body: some Widget {
        CheckWidget()
        ChecksOverviewWidget()
        LogCheckControl()
    }
}
