import WidgetKit

/// Asks WidgetKit to redraw after the app changes checks, logs or what widgets show.
enum WidgetRefresher {
    static func reloadAll() {
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadAllControls()
    }
}
