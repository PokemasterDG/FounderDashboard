import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    enum Section: String, CaseIterable, Hashable, Identifiable {
        case dashboard
        case deckedBuilder
        case lgsFunding
        case imports
        case documents
        case sources

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dashboard: "Dashboard"
            case .deckedBuilder: "Decked Builder"
            case .lgsFunding: "LGS Funding"
            case .imports: "Imports"
            case .documents: "Documents"
            case .sources: "Sources"
            }
        }

        var systemImage: String {
            switch self {
            case .dashboard: "rectangle.grid.2x2"
            case .deckedBuilder: "chart.line.uptrend.xyaxis"
            case .lgsFunding: "dollarsign.circle"
            case .imports: "square.and.arrow.down"
            case .documents: "doc.text"
            case .sources: "list.bullet.clipboard"
            }
        }
    }

    var selectedSection: Section? = .dashboard
    var snapshot: PlanningSnapshot
    var importedReports: [ImportedReport] = []
    var importStatusMessage: String?

    init(snapshot: PlanningSnapshot = AppModel.loadSnapshot()) {
        self.snapshot = snapshot
        self.importedReports = (try? ImportedReportStore.load()) ?? []
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
            importStatusMessage = "Imported \(newlyImported.count) file(s) into FounderDashboard."
        } catch {
            importStatusMessage = error.localizedDescription
        }
    }

    func deleteImportedReport(_ report: ImportedReport) {
        do {
            try ImportedReportStore.delete(report)
            importedReports = try ImportedReportStore.load()
            importStatusMessage = "Removed \(report.originalFileName)."
        } catch {
            importStatusMessage = error.localizedDescription
        }
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
