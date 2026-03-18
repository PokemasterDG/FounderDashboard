import Charts
import SwiftUI

struct LGSFundingView: View {
    let snapshot: FundingSnapshot
    @Binding var launchCashReality: LaunchCashReality
    let launchChecklistTasks: [LaunchChecklistTask]
    let completedTaskIDs: Set<String>
    let onToggleTask: (LaunchChecklistTask) -> Void

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 220), spacing: 16)]
    }

    private var checklistCompletionText: String {
        "\(completedTaskIDs.count) of \(launchChecklistTasks.count) launch-critical tasks complete"
    }

    private var readinessTitle: String {
        let totalCash = launchCashReality.totalCash

        if totalCash >= snapshot.targetCash {
            return "Go Soon"
        }

        if totalCash >= snapshot.strongFloorCash {
            return "Close"
        }

        return "Strengthen First"
    }

    private var readinessDetail: String {
        let totalCash = launchCashReality.totalCash

        if totalCash >= snapshot.targetCash {
            return "Your current inputs meet or exceed the target launch cash threshold."
        }

        if totalCash >= snapshot.strongFloorCash {
            let remaining = snapshot.targetCash - totalCash
            return "You are above the strong floor and about \(remaining.formatted(.currency(code: "USD"))) short of the target case."
        }

        let remaining = snapshot.strongFloorCash - totalCash
        return "You are about \(remaining.formatted(.currency(code: "USD"))) short of the strong floor launch threshold."
    }

    init(
        snapshot: FundingSnapshot,
        launchCashReality: Binding<LaunchCashReality> = .constant(.empty),
        launchChecklistTasks: [LaunchChecklistTask] = [],
        completedTaskIDs: Set<String> = [],
        onToggleTask: @escaping (LaunchChecklistTask) -> Void = { _ in }
    ) {
        self.snapshot = snapshot
        self._launchCashReality = launchCashReality
        self.launchChecklistTasks = launchChecklistTasks
        self.completedTaskIDs = completedTaskIDs
        self.onToggleTask = onToggleTask
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LGS Funding")
                        .font(.largeTitle.weight(.bold))

                    Text("Keep the launch practical, runway-first, and grounded in the founder-led capital stack.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 16) {
                    MetricCard(
                        title: "Current Total Cash",
                        value: launchCashReality.totalCash,
                        format: .currency(code: "USD"),
                        detail: "Your live founder-input total across cash, liquidation, and outside support.",
                        systemImage: "banknote"
                    )
                    MetricCard(
                        title: "Base Cash Need",
                        value: "\(snapshot.baseCashNeedLow.formatted(.currency(code: "USD")))-\(snapshot.baseCashNeedHigh.formatted(.currency(code: "USD")))",
                        detail: "Current base-case launch cash range.",
                        systemImage: "dollarsign.gauge.chart.lefthalf.righthalf"
                    )
                    MetricCard(
                        title: "Liquidation Target",
                        value: snapshot.liquidationTarget.formatted(.currency(code: "USD")),
                        detail: "Current target case for pre-launch inventory liquidation.",
                        systemImage: "shippingbox.fill"
                    )
                    MetricCard(
                        title: "Founder Cash Range",
                        value: "\(snapshot.founderCashLow.formatted(.currency(code: "USD")))-\(snapshot.founderCashHigh.formatted(.currency(code: "USD")))",
                        detail: "Recommended founder-led contribution range right now.",
                        systemImage: "person.crop.circle"
                    )
                    MetricCard(
                        title: "Lead Site",
                        value: snapshot.leadSite,
                        detail: "Best current fit based on the planning repo.",
                        systemImage: "storefront"
                    )
                }

                SectionCard(title: "Current Cash Reality", subtitle: readinessTitle) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(readinessDetail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: columns, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Founder Cash Now")
                                    .font(.headline)

                                TextField(
                                    "0",
                                    value: $launchCashReality.founderCash,
                                    format: .currency(code: "USD")
                                )
                                .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Liquidation Expected")
                                    .font(.headline)

                                TextField(
                                    "0",
                                    value: $launchCashReality.liquidationCash,
                                    format: .currency(code: "USD")
                                )
                                .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Outside Support")
                                    .font(.headline)

                                TextField(
                                    "0",
                                    value: $launchCashReality.outsideSupport,
                                    format: .currency(code: "USD")
                                )
                                .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                }

                SectionCard(title: "Current Recommendation", subtitle: "Founder-led launch posture") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(snapshot.summary)
                            .font(.headline)

                        Label("Lead with \(snapshot.leadSite) unless the lease economics come back worse than expected.", systemImage: "mappin.and.ellipse")
                        Label("Keep outside capital optional in the \(snapshot.outsideCapitalLow.formatted(.currency(code: "USD")))-\(snapshot.outsideCapitalHigh.formatted(.currency(code: "USD"))) range.", systemImage: "creditcard")
                        Label("Retain about \(snapshot.retainedInventoryLow.formatted(.currency(code: "USD")))-\(snapshot.retainedInventoryHigh.formatted(.currency(code: "USD"))) in launch-useful business inventory.", systemImage: "archivebox")
                    }
                }

                SectionCard(title: "Launch Checklist", subtitle: checklistCompletionText) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(launchChecklistTasks) { task in
                            Button {
                                onToggleTask(task)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: completedTaskIDs.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(completedTaskIDs.contains(task.id) ? .green : .secondary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Text(task.detail)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer(minLength: 0)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.secondary.opacity(0.08))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 20) {
                    SectionCard(title: "Launch Cash Scenarios", subtitle: "How the current plan is shaped") {
                        Chart(snapshot.scenarios) { scenario in
                            BarMark(
                                x: .value("Scenario", scenario.name),
                                y: .value("Cash", scenario.totalCash)
                            )
                            .foregroundStyle(.green.gradient)
                            .annotation(position: .top) {
                                Text(scenario.totalCash.formatted(.currency(code: "USD")))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 240)
                    }

                    SectionCard(title: "Site Shortlist", subtitle: "Current first-pass ranking") {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(snapshot.siteCandidates) { candidate in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(candidate.name)
                                            .font(.headline)
                                        Spacer()
                                        Text(candidate.score.formatted(.number.precision(.fractionLength(1))))
                                            .foregroundStyle(.secondary)
                                    }

                                    Text(candidate.summary)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                if candidate.id != snapshot.siteCandidates.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                SectionCard(title: "Guardrails", subtitle: "What not to spend the upside on") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(snapshot.notes, id: \.self) { note in
                            Label(note, systemImage: "exclamationmark.triangle")
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("LGS Funding")
    }
}

#Preview {
    LGSFundingView(
        snapshot: AppModel().snapshot.funding,
        launchCashReality: .constant(.empty),
        launchChecklistTasks: AppModel().launchChecklistTasks,
        completedTaskIDs: AppModel().completedLaunchChecklistTaskIDs
    )
        .frame(width: 1200, height: 900)
}
