import SwiftUI

#if os(iOS)
struct CompanionDashboardView: View {
    @Bindable var model: AppModel

    private var dataStatus: DataStatusCard.Status {
        let insights = model.importedDeckedBuilderInsights

        if insights.importedReportCount == 0 || !insights.hasUsefulData {
            return .seeded
        }

        if insights.activeSubscribers != nil &&
            insights.trailing12MonthProceeds != nil &&
            insights.legacyLifetimeDownloads != nil &&
            insights.legacyIOSActiveDevices30DayAverage != nil {
            return .imported
        }

        return .mixed
    }

    private var dataStatusSummary: String {
        switch dataStatus {
        case .imported:
            return "Decked Builder metrics are fully using imported reports."
        case .seeded:
            return "The app is still using the planning snapshot for most Decked Builder values."
        case .mixed:
            return "Some Decked Builder values are live and some are still seeded."
        }
    }

    private var dataStatusDetail: String {
        if let latestImportDate = model.importedDeckedBuilderInsights.latestImportDate {
            return "Latest import: \(latestImportDate.formatted(.dateTime.month().day().hour().minute()))."
        }

        return "Bring in more reports later on the Mac app to replace the remaining seeded assumptions."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let nextLaunchTask = model.nextLaunchChecklistTask {
                    SectionCard(title: "Next LGS Task", subtitle: "Best current action") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(nextLaunchTask.title)
                                .font(.headline)

                            Text(nextLaunchTask.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    MetricCard(
                        title: "Current Cash",
                        value: model.launchCashReality.totalCash,
                        format: .currency(code: "USD"),
                        detail: "Your current field-facing launch cash total.",
                        systemImage: "banknote"
                    )
                    MetricCard(
                        title: "Target Cash",
                        value: model.snapshot.funding.targetCash,
                        format: .currency(code: "USD"),
                        detail: "Recommended healthier launch threshold.",
                        systemImage: "target"
                    )
                    MetricCard(
                        title: "Lead Site",
                        value: model.snapshot.funding.leadSite,
                        detail: "Current best-ranked location.",
                        systemImage: "mappin.and.ellipse"
                    )
                    MetricCard(
                        title: "Checklist",
                        value: "\(model.completedLaunchChecklistCount)/\(model.launchChecklistTasks.count)",
                        detail: "Launch-critical tasks completed.",
                        systemImage: "checkmark.circle"
                    )
                }

                DataStatusCard(
                    status: dataStatus,
                    summary: dataStatusSummary,
                    detail: dataStatusDetail
                )
            }
            .padding(20)
        }
        .navigationTitle("Dashboard")
    }
}

#Preview {
    NavigationStack {
        CompanionDashboardView(model: AppModel())
    }
}
#endif
