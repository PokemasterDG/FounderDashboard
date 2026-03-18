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

struct FundingScenario: Decodable, Identifiable {
    let name: String
    let totalCash: Double
    let status: String
    let summary: String

    var id: String { name }
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
        ImportedReportStore.storedReportsDirectory.appendingPathComponent(storedFileName)
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
