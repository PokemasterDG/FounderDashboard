import Foundation
import Observation

enum ImportFocus: String, Hashable, Identifiable {
    case salesChart
    case subscriptionReport
    case legacyIOSDownloads
    case legacyIOSActiveDevices

    var id: String { rawValue }

    var title: String {
        switch self {
        case .salesChart: "Sales Chart"
        case .subscriptionReport: "Subscription Report"
        case .legacyIOSDownloads: "Legacy iOS First-Time Downloads"
        case .legacyIOSActiveDevices: "Legacy iOS Active Devices"
        }
    }
}

@MainActor
@Observable
final class AppModel {
    private static let completedChecklistDefaultsKey = "FounderDashboard.completedLaunchChecklistTaskIDs"
    private static let cashRealityDefaultsKey = "FounderDashboard.launchCashReality"

    enum Section: String, CaseIterable, Hashable, Identifiable {
        case dashboard
        case lgsFunding
        case deckedBuilder
        case imports
        case documents
        case sources

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dashboard: "Dashboard"
            case .lgsFunding: "LGS Funding"
            case .deckedBuilder: "Decked Builder"
            case .imports: "Imports"
            case .documents: "Documents"
            case .sources: "Sources"
            }
        }

        var systemImage: String {
            switch self {
            case .dashboard: "rectangle.grid.2x2"
            case .lgsFunding: "dollarsign.circle"
            case .deckedBuilder: "chart.line.uptrend.xyaxis"
            case .imports: "square.and.arrow.down"
            case .documents: "doc.text"
            case .sources: "list.bullet.clipboard"
            }
        }
    }

    var selectedSection: Section? = .dashboard
    var snapshot: PlanningSnapshot
    var importedReports: [ImportedReport] = []
    var importedDeckedBuilderInsights = ImportedDeckedBuilderInsights.empty
    var importStatusMessage: String?
    var importFocus: ImportFocus?
    var completedLaunchChecklistTaskIDs: Set<String>
    var launchCashReality: LaunchCashReality {
        didSet {
            persistLaunchCashReality()
        }
    }

    var launchChecklistTasks: [LaunchChecklistTask] {
        LaunchChecklistTask.starterTasks
    }

    var completedLaunchChecklistCount: Int {
        launchChecklistTasks.filter { completedLaunchChecklistTaskIDs.contains($0.id) }.count
    }

    var nextLaunchChecklistTask: LaunchChecklistTask? {
        launchChecklistTasks.first { !completedLaunchChecklistTaskIDs.contains($0.id) }
    }

    init(snapshot: PlanningSnapshot = AppModel.loadSnapshot()) {
        self.snapshot = snapshot
        self.importedReports = (try? ImportedReportStore.load()) ?? []
        self.completedLaunchChecklistTaskIDs = Set(
            UserDefaults.standard.stringArray(forKey: Self.completedChecklistDefaultsKey) ?? []
        )
        self.launchCashReality = Self.loadLaunchCashReality()
        self.importedDeckedBuilderInsights = ImportedReportAnalyzer.analyze(
            self.importedReports,
            baselineMonthlyOpsCost: snapshot.deckedBuilder.baselineMonthlyOpsCost
        )
    }

    private static func loadSnapshot() -> PlanningSnapshot {
        do {
            return try PlanningSnapshotLoader.load()
        } catch {
            return .fallback
        }
    }

    func importReports(from urls: [URL]) {
        do {
            let newlyImported = try ImportedReportStore.importFiles(from: urls)
            importedReports = try ImportedReportStore.load()
            refreshImportedInsights()
            importStatusMessage = "Imported \(newlyImported.count) file(s) into FounderDashboard."
        } catch {
            importStatusMessage = error.localizedDescription
        }
    }

    func forgetImportedReport(_ report: ImportedReport) {
        do {
            try ImportedReportStore.forget(report)
            importedReports = try ImportedReportStore.load()
            refreshImportedInsights()
            importStatusMessage = "Removed the import reference for \(report.originalFileName)."
        } catch {
            importStatusMessage = error.localizedDescription
        }
    }

    func openImports(focus: ImportFocus) {
        importFocus = focus
        selectedSection = .imports
    }

    func toggleLaunchChecklistTask(_ task: LaunchChecklistTask) {
        if completedLaunchChecklistTaskIDs.contains(task.id) {
            completedLaunchChecklistTaskIDs.remove(task.id)
        } else {
            completedLaunchChecklistTaskIDs.insert(task.id)
        }

        UserDefaults.standard.set(
            Array(completedLaunchChecklistTaskIDs).sorted(),
            forKey: Self.completedChecklistDefaultsKey
        )
    }

    private func refreshImportedInsights() {
        importedDeckedBuilderInsights = ImportedReportAnalyzer.analyze(
            importedReports,
            baselineMonthlyOpsCost: snapshot.deckedBuilder.baselineMonthlyOpsCost
        )
    }

    private static func loadLaunchCashReality() -> LaunchCashReality {
        guard let data = UserDefaults.standard.data(forKey: cashRealityDefaultsKey),
              let decoded = try? JSONDecoder().decode(LaunchCashReality.self, from: data) else {
            return LaunchCashReality.empty
        }

        return decoded
    }

    private func persistLaunchCashReality() {
        guard let data = try? JSONEncoder().encode(launchCashReality) else {
            return
        }

        UserDefaults.standard.set(data, forKey: Self.cashRealityDefaultsKey)
    }
}

private extension PlanningSnapshot {
    static let fallback = PlanningSnapshot(
        generatedOn: "Unavailable",
        deckedBuilder: DeckedBuilderSnapshot(
            activeSubscribers: 0,
            appleProceedsTrailing12: 0,
            appleProceedsTrailing3: 0,
            appCashAvailable: 0,
            cashAvailableForStore: 0,
            baselineMonthlyOpsCost: 0,
            usSubscriberShare: 0,
            sixMonthSubscribers: 0,
            oneMonthSubscribers: 0,
            legacyLifetimeDownloads: 0,
            legacyIOSActiveDevices30DayAverage: 0,
            legacyIOSActiveDevices90DayAverage: 0,
            targetMilestone: "Load planning snapshot",
            androidRevenueLow: 0,
            androidRevenueHigh: 0,
            notes: ["Planning snapshot failed to load."],
            revenueSeries: []
        ),
        funding: FundingSnapshot(
            baseCashNeedLow: 0,
            baseCashNeedHigh: 0,
            strongFloorCash: 0,
            targetCash: 0,
            saferCash: 0,
            liquidationTarget: 0,
            founderCashLow: 0,
            founderCashHigh: 0,
            outsideCapitalLow: 0,
            outsideCapitalHigh: 0,
            retainedInventoryLow: 0,
            retainedInventoryHigh: 0,
            leadSite: "Unavailable",
            secondSite: "Unavailable",
            summary: "Planning snapshot failed to load.",
            notes: ["Rebuild the app bundle resources and try again."],
            siteCandidates: [],
            scenarios: []
        ),
        documents: [],
        sources: []
    )
}
