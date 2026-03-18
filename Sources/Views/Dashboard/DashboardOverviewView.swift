import Charts
import SwiftUI

struct DashboardOverviewView: View {
    let snapshot: PlanningSnapshot
    let importedInsights: ImportedDeckedBuilderInsights
    let nextLaunchTask: LaunchChecklistTask?
    let onRequestImportFocus: (ImportFocus) -> Void

    private var decked: [GridItem] {
        [GridItem(.adaptive(minimum: 220), spacing: 16)]
    }

    private var subscriberCount: Int {
        importedInsights.activeSubscribers ?? snapshot.deckedBuilder.activeSubscribers
    }

    private var netSupportValue: Double {
        importedInsights.netMonthlySupportEstimate ?? snapshot.deckedBuilder.netSupportEstimate
    }

    private var downloadCount: Int {
        importedInsights.legacyLifetimeDownloads ?? snapshot.deckedBuilder.legacyLifetimeDownloads
    }

    private var revenueSeries: [RevenuePoint] {
        importedInsights.revenueSeries.isEmpty ? snapshot.deckedBuilder.revenueSeries : importedInsights.revenueSeries
    }

    private var deckedNotes: [String] {
        importedInsights.notes.isEmpty ? snapshot.deckedBuilder.notes : importedInsights.notes
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
            return "The Decked Builder overview is using imported App Store Connect data."
        case .seeded:
            return "The overview is still using the planning snapshot."
        case .mixed:
            return "The overview is using a mix of imported reports and seeded planning values."
        }
    }

    private var dataStatusDetail: String {
        if let latestImportDate = importedInsights.latestImportDate {
            return "Latest import: \(latestImportDate.formatted(.dateTime.month().day().year().hour().minute())). Import more report types to replace any remaining seeded fields."
        }

        return "Bring in sales charts, subscription reports, and legacy analytics exports to replace the seeded assumptions."
    }

    init(
        snapshot: PlanningSnapshot,
        importedInsights: ImportedDeckedBuilderInsights = .empty,
        nextLaunchTask: LaunchChecklistTask? = nil,
        onRequestImportFocus: @escaping (ImportFocus) -> Void = { _ in }
    ) {
        self.snapshot = snapshot
        self.importedInsights = importedInsights
        self.nextLaunchTask = nextLaunchTask
        self.onRequestImportFocus = onRequestImportFocus
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Founder Overview")
                        .font(.largeTitle.weight(.bold))

                    Text("A macOS-first control panel for Decked Builder cash flow, legacy recovery, and Circle City Gaming launch readiness.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .top, spacing: 20) {
                    if let nextLaunchTask {
                        SectionCard(title: "Next LGS Task", subtitle: "Best current store-launch action") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(nextLaunchTask.title)
                                    .font(.headline)

                                Text(nextLaunchTask.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Label("Open LGS Funding to track it in the launch checklist.", systemImage: "arrow.right.circle")
                                    .font(.subheadline)
                            }
                        }
                    }

                    SectionCard(title: "Current Recommendation", subtitle: "What the plan says right now") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(snapshot.funding.summary)
                                .font(.headline)

                            Label("Lead site: \(snapshot.funding.leadSite)", systemImage: "mappin.and.ellipse")
                            Label("Liquidation target case: \(snapshot.funding.liquidationTarget, format: .currency(code: "USD"))", systemImage: "shippingbox")
                            Label("Strong floor launch cash: \(snapshot.funding.strongFloorCash, format: .currency(code: "USD"))", systemImage: "shield")
                        }
                        .font(.subheadline)
                    }
                }

                LazyVGrid(columns: decked, alignment: .leading, spacing: 16) {
                    MetricCard(
                        title: "Launch Target Cash",
                        value: snapshot.funding.targetCash, format: .currency(code: "USD"),
                        detail: "Current recommended target for a healthier founder-led store launch.",
                        systemImage: "target"
                    )
                    MetricCard(
                        title: "Decked Builder Subscribers",
                        value: "\(subscriberCount)",
                        detail: importedInsights.activeSubscribers == nil
                            ? "Current active Remastered subscriptions from the planning snapshot."
                            : "Current active Remastered subscriptions from your imported subscription report.",
                        systemImage: "person.3.fill"
                    )
                    MetricCard(
                        title: "App Net Monthly Support",
                        value: netSupportValue, format: .currency(code: "USD"),
                        detail: importedInsights.netMonthlySupportEstimate == nil
                            ? "Trailing-12 Apple proceeds minus baseline monthly app ops costs from the planning snapshot."
                            : "Trailing-12 imported Apple proceeds minus baseline monthly app ops costs.",
                        systemImage: "waveform.path.ecg"
                    )
                    MetricCard(
                        title: "Legacy Apple Downloads",
                        value: "\(downloadCount.formatted())",
                        detail: importedInsights.legacyLifetimeDownloads == nil
                            ? "Combined lifetime first-time downloads across the old Apple app exports reviewed so far."
                            : "Combined lifetime first-time downloads across the imported legacy Apple app exports.",
                        systemImage: "arrow.down.circle"
                    )
                    MetricCard(
                        title: "Decked Coverage",
                        value: "\(importedInsights.coreCoveragePercent)%",
                        detail: importedInsights.coreCoverageSummary,
                        systemImage: "checklist"
                    )
                }

                DataStatusCard(
                    status: dataStatus,
                    summary: dataStatusSummary,
                    detail: dataStatusDetail
                )

                SectionCard(title: "Coverage Breakdown", subtitle: "Which core metrics are imported right now") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(importedInsights.coverageItems) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Label(
                                    item.title,
                                    systemImage: item.isImported ? "checkmark.circle.fill" : "circle.dashed"
                                )
                                .foregroundStyle(item.isImported ? .green : .secondary)

                                if !item.isImported {
                                    Button {
                                        onRequestImportFocus(item.importFocus)
                                    } label: {
                                        Text(item.recommendation)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.leading, 24)
                                }
                            }
                        }
                    }
                    .font(.subheadline)
                }

                HStack(alignment: .top, spacing: 20) {
                    SectionCard(title: "Decked Builder Trend", subtitle: "Most recent seeded monthly proceeds") {
                        Chart(revenueSeries) { point in
                            BarMark(
                                x: .value("Month", point.label),
                                y: .value("Proceeds", point.amount)
                            )
                            .foregroundStyle(.orange.gradient)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 220)
                    }

                    SectionCard(title: "Decked Builder Notes", subtitle: "What matters for the next phase") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(deckedNotes, id: \.self) { note in
                                Label(note, systemImage: "checkmark.circle")
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                SectionCard(title: "LGS Funding Notes", subtitle: "Current operating guardrails") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(snapshot.funding.notes, id: \.self) { note in
                            Label(note, systemImage: "dollarsign.circle")
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
            }
            .padding(24)
        }
        .navigationTitle("Dashboard")
    }
}

#Preview {
    DashboardOverviewView(
        snapshot: AppModel().snapshot,
        importedInsights: AppModel().importedDeckedBuilderInsights,
        nextLaunchTask: AppModel().nextLaunchChecklistTask
    )
        .frame(width: 1200, height: 900)
}
