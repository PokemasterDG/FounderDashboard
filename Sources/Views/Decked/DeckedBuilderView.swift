import Charts
import SwiftUI

struct DeckedBuilderView: View {
    let snapshot: DeckedBuilderSnapshot

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 220), spacing: 16)]
    }

    init(snapshot: DeckedBuilderSnapshot) {
        self.snapshot = snapshot
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

                LazyVGrid(columns: columns, spacing: 16) {
                    MetricCard(
                        title: "Active Subscribers",
                        value: "\(snapshot.activeSubscribers)",
                        detail: "Current live subscriptions in Remastered.",
                        systemImage: "person.2.fill"
                    )
                    MetricCard(
                        title: "Trailing 12-Month Proceeds",
                        value: snapshot.appleProceedsTrailing12,
                        format: .currency(code: "USD"),
                        detail: "Average monthly Apple proceeds over the last 12 active months.",
                        systemImage: "calendar"
                    )
                    MetricCard(
                        title: "Net Monthly Support",
                        value: snapshot.netSupportEstimate,
                        format: .currency(code: "USD"),
                        detail: "Current baseline support after app infrastructure costs.",
                        systemImage: "banknote"
                    )
                    MetricCard(
                        title: "Legacy iOS Active Devices",
                        value: snapshot.legacyIOSActiveDevices30DayAverage.formatted(.number.precision(.fractionLength(0))),
                        detail: "Average active devices across the last 30 days on the legacy iOS app export.",
                        systemImage: "iphone"
                    )
                }

                HStack(alignment: .top, spacing: 20) {
                    SectionCard(title: "Proceeds Trend", subtitle: "Seeded from App Store Connect exports") {
                        Chart {
                            ForEach(snapshot.revenueSeries) { point in
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
                        Chart([
                            ("6 Month", snapshot.sixMonthSubscribers),
                            ("1 Month", snapshot.oneMonthSubscribers)
                        ], id: \.0) { item in
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
                            Label("\(snapshot.legacyLifetimeDownloads.formatted()) lifetime first-time downloads across the reviewed legacy Apple exports.", systemImage: "tray.full")
                            Label("\(snapshot.usSubscriberShare.formatted(.number.precision(.fractionLength(1))))% of the current subscription snapshot is US-based.", systemImage: "globe.americas")
                            Label("Android currently adds about \(snapshot.androidRevenueLow, format: .currency(code: "USD"))-\(snapshot.androidRevenueHigh, format: .currency(code: "USD")) per month, but it remains upside rather than baseline.", systemImage: "ellipsis.rectangle")
                        }
                    }

                    SectionCard(title: "Current Milestone", subtitle: "Operational focus") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(snapshot.targetMilestone)
                                .font(.headline)

                            ForEach(snapshot.notes, id: \.self) { note in
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
    DeckedBuilderView(snapshot: AppModel().snapshot.deckedBuilder)
        .frame(width: 1200, height: 900)
}
