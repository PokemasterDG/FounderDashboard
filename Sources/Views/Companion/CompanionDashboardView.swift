import SwiftUI

#if os(iOS)
struct CompanionDashboardView: View {
    @Bindable var model: CompanionModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if model.isHydratingSnapshot {
                    SectionCard(title: "Loading Planning Snapshot", subtitle: "Refreshing store planning context") {
                        HStack(spacing: 12) {
                            ProgressView()

                            Text("Pulling in the latest bundled funding snapshot.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

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
                        value: model.funding.targetCash,
                        format: .currency(code: "USD"),
                        detail: "Recommended healthier launch threshold.",
                        systemImage: "target"
                    )
                    MetricCard(
                        title: "Lead Site",
                        value: model.funding.leadSite,
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

                SectionCard(title: "Decked Builder Context", subtitle: "Reference while you are out") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("The companion app uses the latest bundled planning snapshot so site runs stay fast and responsive.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Use the Mac app for imported report analysis and deeper Decked Builder metrics.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Dashboard")
    }
}

#Preview {
    NavigationStack {
        CompanionDashboardView(model: CompanionModel())
    }
}
#endif
