import Charts
import SwiftUI

struct DashboardOverviewView: View {
    let snapshot: PlanningSnapshot

    private var decked: [GridItem] {
        [GridItem(.adaptive(minimum: 220), spacing: 16)]
    }

    init(snapshot: PlanningSnapshot) {
        self.snapshot = snapshot
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Founder Overview")
                        .font(.largeTitle.weight(.bold))

                    Text("A macOS-first control panel for software cash flow, legacy recovery, and local game store launch readiness.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: decked, alignment: .leading, spacing: 16) {
                    MetricCard(
                        title: "Decked Builder Subscribers",
                        value: "\(snapshot.deckedBuilder.activeSubscribers)",
                        detail: "Current active Remastered subscriptions.",
                        systemImage: "person.3.fill"
                    )
                    MetricCard(
                        title: "App Net Monthly Support",
                        value: snapshot.deckedBuilder.netSupportEstimate, format: .currency(code: "USD"),
                        detail: "Trailing-12 Apple proceeds minus baseline monthly app ops costs.",
                        systemImage: "waveform.path.ecg"
                    )
                    MetricCard(
                        title: "Launch Target Cash",
                        value: snapshot.funding.targetCash, format: .currency(code: "USD"),
                        detail: "Current recommended target for a healthier founder-led store launch.",
                        systemImage: "target"
                    )
                    MetricCard(
                        title: "Legacy Apple Downloads",
                        value: "\(snapshot.deckedBuilder.legacyLifetimeDownloads.formatted())",
                        detail: "Combined lifetime first-time downloads across the old Apple app exports reviewed so far.",
                        systemImage: "arrow.down.circle"
                    )
                }

                HStack(alignment: .top, spacing: 20) {
                    SectionCard(title: "Decked Builder Trend", subtitle: "Most recent seeded monthly proceeds") {
                        Chart(snapshot.deckedBuilder.revenueSeries) { point in
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

                HStack(alignment: .top, spacing: 20) {
                    SectionCard(title: "Decked Builder Notes", subtitle: "What matters for the next phase") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(snapshot.deckedBuilder.notes, id: \.self) { note in
                                Label(note, systemImage: "checkmark.circle")
                                    .fixedSize(horizontal: false, vertical: true)
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
            }
            .padding(24)
        }
        .navigationTitle("Dashboard")
    }
}

#Preview {
    DashboardOverviewView(snapshot: AppModel().snapshot)
        .frame(width: 1200, height: 900)
}
