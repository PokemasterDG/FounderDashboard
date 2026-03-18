import Foundation

struct PlanningSnapshot: Decodable {
    let generatedOn: String
    let deckedBuilder: DeckedBuilderSnapshot
    let funding: FundingSnapshot
    let documents: [PlanningDocument]
    let sources: [SourceRecord]
}

struct DeckedBuilderSnapshot: Decodable {
    let activeSubscribers: Int
    let appleProceedsTrailing12: Double
    let appleProceedsTrailing3: Double
    let appCashAvailable: Double
    let cashAvailableForStore: Double
    let baselineMonthlyOpsCost: Double
    let usSubscriberShare: Double
    let sixMonthSubscribers: Int
    let oneMonthSubscribers: Int
    let legacyLifetimeDownloads: Int
    let legacyIOSActiveDevices30DayAverage: Double
    let legacyIOSActiveDevices90DayAverage: Double
    let targetMilestone: String
    let androidRevenueLow: Double
    let androidRevenueHigh: Double
    let notes: [String]
    let revenueSeries: [RevenuePoint]

    var netSupportEstimate: Double {
        max(appleProceedsTrailing12 - baselineMonthlyOpsCost, 0)
    }
}

struct RevenuePoint: Decodable, Identifiable {
    let label: String
    let amount: Double

    var id: String { label }
}

struct FundingSnapshot: Decodable {
    let baseCashNeedLow: Double
    let baseCashNeedHigh: Double
    let strongFloorCash: Double
    let targetCash: Double
    let saferCash: Double
    let liquidationTarget: Double
    let founderCashLow: Double
    let founderCashHigh: Double
    let outsideCapitalLow: Double
    let outsideCapitalHigh: Double
    let retainedInventoryLow: Double
    let retainedInventoryHigh: Double
    let leadSite: String
    let secondSite: String
    let summary: String
    let notes: [String]
    let siteCandidates: [SiteCandidate]
    let scenarios: [FundingScenario]
}

struct SiteCandidate: Decodable, Identifiable {
    let name: String
    let score: Double
    let summary: String

    var id: String { name }
}

enum SitePipelineStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case toured
    case dead

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: "Active"
        case .toured: "Toured"
        case .dead: "Dead"
        }
    }

    var systemImage: String {
        switch self {
        case .active: "bolt.circle"
        case .toured: "car.circle"
        case .dead: "xmark.circle"
        }
    }
}

struct FundingScenario: Decodable, Identifiable {
    let name: String
    let totalCash: Double
    let status: String
    let summary: String

    var id: String { name }
}

struct LaunchChecklistTask: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String

    static let starterTasks: [LaunchChecklistTask] = [
        LaunchChecklistTask(
            id: "site-tour",
            title: "Tour the top three sites",
            detail: "Visit 855 N High School Rd, 5735 Crawfordsville Rd, and 7301 Rockville Rd in the evening and update parking, safety, and visibility notes."
        ),
        LaunchChecklistTask(
            id: "broker-rent",
            title: "Get real rent numbers",
            detail: "Ask brokers for base rent, CAM, event-use approval, and signage rights so the shortlist can move from estimated to real economics."
        ),
        LaunchChecklistTask(
            id: "liquidation-plan",
            title: "Map the $50k liquidation plan",
            detail: "Break the pre-launch inventory sale target into concrete Pokemon and Magic batches with a timing plan."
        ),
        LaunchChecklistTask(
            id: "founder-cash",
            title: "Lock the founder cash range",
            detail: "Decide what founder cash can go in without recreating personal fragility."
        ),
        LaunchChecklistTask(
            id: "decked-2-launch",
            title: "Stabilize Decked Builder 2.0.0",
            detail: "Keep the app on track for the MagicCon Las Vegas runway so it can support the store as recurring cash flow."
        ),
        LaunchChecklistTask(
            id: "funding-go-no-go",
            title: "Set a launch go/no-go threshold",
            detail: "Decide the minimum real cash and runway conditions required before signing a lease."
        )
    ]
}

struct LaunchCashReality: Codable, Equatable {
    var founderCash: Double
    var liquidationCash: Double
    var outsideSupport: Double

    var totalCash: Double {
        founderCash + liquidationCash + outsideSupport
    }

    static let empty = LaunchCashReality(
        founderCash: 0,
        liquidationCash: 0,
        outsideSupport: 0
    )
}

struct PlanningDocument: Decodable, Identifiable {
    let title: String
    let summary: String
    let path: String

    var id: String { path }
    var url: URL { URL(filePath: path) }
}

struct SourceRecord: Decodable, Identifiable {
    let title: String
    let kind: String
    let detail: String

    var id: String { title }
}

struct ImportedReport: Codable, Identifiable, Hashable {
    let id: UUID
    let originalFileName: String
    let storedFileName: String
    let importedAt: Date
    let fileSize: Int64
    let detectedKind: ReportKind

    var storedFileURL: URL {
        ImportedReportStorage.storedReportsDirectory.appendingPathComponent(storedFileName)
    }
}

struct ImportedDeckedBuilderInsights {
    let importedReportCount: Int
    let latestImportDate: Date?
    let activeSubscribers: Int?
    let sixMonthSubscribers: Int?
    let oneMonthSubscribers: Int?
    let usSubscriberShare: Double?
    let trailing12MonthProceeds: Double?
    let trailing3MonthProceeds: Double?
    let netMonthlySupportEstimate: Double?
    let revenueSeries: [RevenuePoint]
    let legacyLifetimeDownloads: Int?
    let legacyIOSActiveDevices30DayAverage: Double?
    let legacyIOSActiveDevices90DayAverage: Double?
    let notes: [String]

    struct CoverageItem: Identifiable {
        let title: String
        let isImported: Bool
        let recommendation: String
        let importFocus: ImportFocus

        var id: String { title }
    }

    private var coveredMetricCount: Int {
        [
            activeSubscribers != nil,
            trailing12MonthProceeds != nil,
            legacyLifetimeDownloads != nil,
            legacyIOSActiveDevices30DayAverage != nil
        ]
        .filter { $0 }
        .count
    }

    var coreCoverageTotalCount: Int { 4 }

    var coreCoverageRatio: Double {
        Double(coveredMetricCount) / Double(coreCoverageTotalCount)
    }

    var coreCoveragePercent: Int {
        Int((coreCoverageRatio * 100).rounded())
    }

    var coreCoverageSummary: String {
        "\(coveredMetricCount) of \(coreCoverageTotalCount) core Decked Builder metrics are currently coming from imported reports."
    }

    var coverageItems: [CoverageItem] {
        [
            CoverageItem(
                title: "Active subscribers",
                isImported: activeSubscribers != nil,
                recommendation: "Import a Subscription Report export to replace the seeded subscriber count and plan mix.",
                importFocus: .subscriptionReport
            ),
            CoverageItem(
                title: "Trailing 12-month proceeds",
                isImported: trailing12MonthProceeds != nil,
                recommendation: "Import an itunes_sales_chart CSV to replace the seeded Apple proceeds assumptions.",
                importFocus: .salesChart
            ),
            CoverageItem(
                title: "Legacy lifetime downloads",
                isImported: legacyLifetimeDownloads != nil,
                recommendation: "Import first_time_downloads exports for the legacy Apple apps, starting with iOS and visionOS.",
                importFocus: .legacyIOSDownloads
            ),
            CoverageItem(
                title: "Legacy iOS active devices",
                isImported: legacyIOSActiveDevices30DayAverage != nil,
                recommendation: "Import an active_devices export for the legacy iOS and visionOS app to replace the seeded activity averages.",
                importFocus: .legacyIOSActiveDevices
            )
        ]
    }

    var hasUsefulData: Bool {
        activeSubscribers != nil ||
        trailing12MonthProceeds != nil ||
        legacyLifetimeDownloads != nil ||
        legacyIOSActiveDevices30DayAverage != nil
    }

    static let empty = ImportedDeckedBuilderInsights(
        importedReportCount: 0,
        latestImportDate: nil,
        activeSubscribers: nil,
        sixMonthSubscribers: nil,
        oneMonthSubscribers: nil,
        usSubscriberShare: nil,
        trailing12MonthProceeds: nil,
        trailing3MonthProceeds: nil,
        netMonthlySupportEstimate: nil,
        revenueSeries: [],
        legacyLifetimeDownloads: nil,
        legacyIOSActiveDevices30DayAverage: nil,
        legacyIOSActiveDevices90DayAverage: nil,
        notes: []
    )
}

enum ReportKind: String, Codable, CaseIterable {
    case appStoreSalesChart
    case appStoreSalesTable
    case subscriptionReport
    case subscriberReport
    case subscriptionEventReport
    case winBackReport
    case appAnalyticsDownloads
    case appAnalyticsActiveDevices
    case unknown

    var title: String {
        switch self {
        case .appStoreSalesChart: "Sales Chart"
        case .appStoreSalesTable: "Sales Table"
        case .subscriptionReport: "Subscription Report"
        case .subscriberReport: "Subscriber Report"
        case .subscriptionEventReport: "Subscription Event Report"
        case .winBackReport: "Win-Back Report"
        case .appAnalyticsDownloads: "Analytics Downloads"
        case .appAnalyticsActiveDevices: "Analytics Active Devices"
        case .unknown: "Unknown Report"
        }
    }
}
