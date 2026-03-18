import Charts
import SwiftUI

struct DeckedBuilderView: View {
    let snapshot: DeckedBuilderSnapshot
    let importedInsights: ImportedDeckedBuilderInsights

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 220), spacing: 16)]
    }

    private var activeSubscribersValue: Int {
        importedInsights.activeSubscribers ?? snapshot.activeSubscribers
    }

    private var trailing12ProceedsValue: Double {
        importedInsights.trailing12MonthProceeds ?? snapshot.appleProceedsTrailing12
    }

    private var netMonthlySupportValue: Double {
        importedInsights.netMonthlySupportEstimate ?? snapshot.netSupportEstimate
    }

    private var legacyActiveDevices30DayValue: Double {
        importedInsights.legacyIOSActiveDevices30DayAverage ?? snapshot.legacyIOSActiveDevices30DayAverage
    }

    private var subscriberMix: [(String, Int)] {
        [
            ("6 Month", importedInsights.sixMonthSubscribers ?? snapshot.sixMonthSubscribers),
            ("1 Month", importedInsights.oneMonthSubscribers ?? snapshot.oneMonthSubscribers)
        ]
    }

    private var revenueSeries: [RevenuePoint] {
        importedInsights.revenueSeries.isEmpty ? snapshot.revenueSeries : importedInsights.revenueSeries
    }

    private var legacyLifetimeDownloadsValue: Int {
        importedInsights.legacyLifetimeDownloads ?? snapshot.legacyLifetimeDownloads
    }

    private var usSubscriberShareValue: Double {
        importedInsights.usSubscriberShare ?? snapshot.usSubscriberShare
    }

    private var dataStatus: DataStatusCard.Status {
        if importedInsights.importedReportCount == 0 || !importedInsights.hasUsefulData {
            return .seeded
        }

        if importedInsights.activeSubscribers != nil &&
            importedInsights.trailing12MonthProceeds != nil &&
            importedInsights.legacyLifetimeDownloads != nil &&
            importedInsights.legacyIOSActiveDevices30DayAverage != nil {
            return .imported
        }

        return .mixed
    }

    private var dataStatusSummary: String {
        switch dataStatus {
        case .imported:
            return "Decked Builder metrics are currently using imported report data."
        case .seeded:
            return "Decked Builder is still showing the bundled planning snapshot."
        case .mixed:
            return "Some Decked Builder metrics are imported and some are still seeded."
        }
    }

    private var dataStatusDetail: String {
        if let latestImportDate = importedInsights.latestImportDate {
            return "Latest import: \(latestImportDate.formatted(.dateTime.month().day().year().hour().minute())). Import the missing report types to replace the remaining seeded metrics."
        }

        return "Import App Store Connect sales, subscription, and analytics exports to replace the seeded assumptions."
    }

    init(snapshot: DeckedBuilderSnapshot, importedInsights: ImportedDeckedBuilderInsights = .empty) {
        self.snapshot = snapshot
        self.importedInsights = importedInsights
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Decked Builder")
                        .font(.largeTitle.weight(.bold))

                    Text("Track current recurring support, legacy recovery opportunity, and rebuild timing.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                DataStatusCard(
                    status: dataStatus,
                    summary: dataStatusSummary,
                    detail: dataStatusDetail
                )

                LazyVGrid(columns: columns, spacing: 16) {
                    MetricCard(
                        title: "Active Subscribers",
                        value: "\(activeSubscribersValue)",
                        detail: importedInsights.activeSubscribers == nil
                            ? "Current live subscriptions from the planning snapshot."
                            : "Current live subscriptions from your latest imported subscription report.",
                        systemImage: "person.2.fill"
                    )
                    MetricCard(
                        title: "Trailing 12-Month Proceeds",
                        value: trailing12ProceedsValue,
                        format: .currency(code: "USD"),
                        detail: importedInsights.trailing12MonthProceeds == nil
                            ? "Average monthly Apple proceeds from the planning snapshot."
                            : "Average monthly Apple proceeds over the last 12 active months from the latest imported sales chart.",
                        systemImage: "calendar"
                    )
                    MetricCard(
                        title: "Net Monthly Support",
                        value: netMonthlySupportValue,
                        format: .currency(code: "USD"),
                        detail: importedInsights.netMonthlySupportEstimate == nil
                            ? "Current baseline support after app infrastructure costs from the planning snapshot."
                            : "Imported trailing-12 proceeds minus baseline app infrastructure costs.",
                        systemImage: "banknote"
                    )
                    MetricCard(
                        title: "Legacy iOS Active Devices",
                        value: legacyActiveDevices30DayValue.formatted(.number.precision(.fractionLength(0))),
                        detail: importedInsights.legacyIOSActiveDevices30DayAverage == nil
                            ? "Average active devices across the last 30 days from the planning snapshot."
                            : "Average active devices across the last 30 days from the latest imported legacy iOS active-device export.",
                        systemImage: "iphone"
                    )
                }

                HStack(alignment: .top, spacing: 20) {
                    SectionCard(title: "Proceeds Trend", subtitle: "Seeded from App Store Connect exports") {
                        Chart {
                            ForEach(revenueSeries) { point in
                                LineMark(
                                    x: .value("Month", point.label),
                                    y: .value("Proceeds", point.amount)
                                )
                                .foregroundStyle(.orange)
                                .symbol(.circle)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 240)
                    }

                    SectionCard(title: "Subscriber Mix", subtitle: "Current subscription structure") {
                        Chart(subscriberMix, id: \.0) { item in
                            SectorMark(
                                angle: .value("Subscribers", item.1),
                                innerRadius: .ratio(0.55)
                            )
                            .foregroundStyle(by: .value("Plan", item.0))
                        }
                        .chartLegend(position: .bottom, spacing: 18)
                        .frame(height: 240)
                    }
                }

                HStack(alignment: .top, spacing: 20) {
                    SectionCard(title: "Recovery Read", subtitle: "Why the legacy base matters") {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("\(legacyLifetimeDownloadsValue.formatted()) lifetime first-time downloads across the reviewed legacy Apple exports.", systemImage: "tray.full")
                            Label("\(usSubscriberShareValue.formatted(.number.precision(.fractionLength(1))))% of the current subscription snapshot is US-based.", systemImage: "globe.americas")
                            Label("Android currently adds about \(snapshot.androidRevenueLow, format: .currency(code: "USD"))-\(snapshot.androidRevenueHigh, format: .currency(code: "USD")) per month, but it remains upside rather than baseline.", systemImage: "ellipsis.rectangle")
                        }
                    }

                    SectionCard(title: "Current Milestone", subtitle: "Operational focus") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(snapshot.targetMilestone)
                                .font(.headline)

                            ForEach(importedInsights.notes.isEmpty ? snapshot.notes : importedInsights.notes, id: \.self) { note in
                                Label(note, systemImage: "hammer")
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Decked Builder")
    }
}

#Preview {
    DeckedBuilderView(
        snapshot: AppModel().snapshot.deckedBuilder,
        importedInsights: AppModel().importedDeckedBuilderInsights
    )
        .frame(width: 1200, height: 900)
}
