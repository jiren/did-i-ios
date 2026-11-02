import Foundation
import Observation

/// The Stats screen: one report per range, built on first use and kept until the next reload.
@Observable
final class StatsViewModel {
    private(set) var range: StatsRange = .week
    private(set) var report: StatsReport?
    /// The chosen bar's id; nil means the last one, as the design opens.
    private(set) var selectedBarID: String?
    private(set) var errorMessage: String?

    @ObservationIgnored private let checkStore: any CheckStoring & CategoryStoring
    @ObservationIgnored private let logStore: any LogStoring
    @ObservationIgnored private let days: any DayBoundaryProviding
    @ObservationIgnored private let timeSource: any TimeSource
    @ObservationIgnored private let locale: Locale
    @ObservationIgnored private var history: StatsHistory?
    @ObservationIgnored private var reports: [StatsRange: StatsReport] = [:]

    init(
        checkStore: any CheckStoring & CategoryStoring,
        logStore: any LogStoring,
        days: any DayBoundaryProviding,
        timeSource: any TimeSource,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.checkStore = checkStore
        self.logStore = logStore
        self.days = days
        self.timeSource = timeSource
        self.locale = locale
    }

    var selectedBar: StatsReport.Bar? {
        guard let bars = report?.bars else { return nil }
        return bars.first { $0.id == selectedBarID } ?? bars.last
    }

    func reload() {
        do {
            history = StatsHistory(
                categories: try checkStore.categories(),
                checks: try checkStore.checks(),
                logs: try logStore.logs(for: nil, limit: nil),
                boundary: days.dayBoundary
            )
            reports = [:]
            errorMessage = nil
            showReport()
        } catch {
            errorMessage = String(localized: "Couldn’t read your stats.")
        }
    }

    func selectRange(_ range: StatsRange) {
        guard range != self.range else { return }
        self.range = range
        selectedBarID = nil
        showReport()
    }

    func selectBar(_ id: String) {
        guard report?.bars.contains(where: { $0.id == id }) == true else { return }
        selectedBarID = id
    }

    private func showReport() {
        if let cached = reports[range] {
            report = cached
        } else if let history {
            let built = StatsReport(range: range, history: history, now: timeSource.now, locale: locale)
            reports[range] = built
            report = built
        }
    }
}
