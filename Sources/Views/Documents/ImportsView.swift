import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ImportsView: View {
    @Bindable var model: AppModel
    @State private var isImporting = false

    private let supportedTypes: [UTType] = [
        .commaSeparatedText,
        .plainText,
        .utf8PlainText,
        .tabSeparatedText
    ]

    init(model: AppModel) {
        self.model = model
    }

    private var checklistItems: [ImportChecklistItem] {
        let reports = model.importedReports

        return [
            ImportChecklistItem(
                title: "Sales Chart",
                detail: "Needed for trailing proceeds, recent revenue trend, and net monthly support.",
                isComplete: reports.contains(where: { $0.detectedKind == .appStoreSalesChart })
            ),
            ImportChecklistItem(
                title: "Subscription Report",
                detail: "Needed for active subscribers, plan mix, and US subscriber share.",
                isComplete: reports.contains(where: { $0.detectedKind == .subscriptionReport })
            ),
            ImportChecklistItem(
                title: "Legacy iOS First-Time Downloads",
                detail: "Needed for the imported lifetime legacy-download count.",
                isComplete: reports.contains(where: {
                    $0.detectedKind == .appAnalyticsDownloads &&
                    $0.originalFileName.lowercased().contains("decked_builder (ios and visionos)")
                })
            ),
            ImportChecklistItem(
                title: "Legacy iOS Active Devices",
                detail: "Needed for imported 30-day and 90-day active-device averages.",
                isComplete: reports.contains(where: {
                    $0.detectedKind == .appAnalyticsActiveDevices &&
                    $0.originalFileName.lowercased().contains("decked_builder (ios and visionos)")
                })
            )
        ]
    }

    private var completedChecklistCount: Int {
        checklistItems.filter(\.isComplete).count
    }

    private var nextNeededChecklistItem: ImportChecklistItem? {
        checklistItems.first(where: { !$0.isComplete })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Imports")
                        .font(.largeTitle.weight(.bold))

                    Text("Bring App Store Connect exports into the app so the dashboard can move from seeded snapshots toward live working data.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                SectionCard(title: "Import Reports", subtitle: "CSV and text exports from App Store Connect") {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Button("Import Files") {
                                isImporting = true
                            }

                            Text("Supported: CSV, tab-delimited text, and report exports.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let status = model.importStatusMessage {
                            Label(status, systemImage: "info.circle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                SectionCard(title: "Imported Reports", subtitle: "\(model.importedReports.count) file(s) currently copied into FounderDashboard storage") {
                    if model.importedReports.isEmpty {
                        Text("No reports imported yet. Start with your App Store Connect CSVs and subscription text exports.")
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 14) {
                            ForEach(model.importedReports) { report in
                                ImportedReportRow(report: report) {
                                    NSWorkspace.shared.open(report.storedFileURL)
                                } onReveal: {
                                    NSWorkspace.shared.activateFileViewerSelecting([report.storedFileURL])
                                } onDelete: {
                                    model.deleteImportedReport(report)
                                }

                                if report.id != model.importedReports.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                SectionCard(title: "Recognized Data", subtitle: "What the app is currently able to use from imported reports") {
                    if !model.importedDeckedBuilderInsights.hasUsefulData {
                        Text("No imported metrics are active yet. Once a report is recognized, this section will show exactly what changed.")
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            if let latestImportDate = model.importedDeckedBuilderInsights.latestImportDate {
                                Label(
                                    "Latest import: \(latestImportDate.formatted(.dateTime.month().day().year().hour().minute()))",
                                    systemImage: "clock"
                                )
                                .foregroundStyle(.secondary)
                            }

                            if let activeSubscribers = model.importedDeckedBuilderInsights.activeSubscribers {
                                Label("Active subscribers from imported reports: \(activeSubscribers)", systemImage: "person.2.fill")
                            }

                            if let trailing12MonthProceeds = model.importedDeckedBuilderInsights.trailing12MonthProceeds {
                                Label(
                                    "Trailing 12-month proceeds from imported sales charts: \(trailing12MonthProceeds.formatted(.currency(code: "USD")))",
                                    systemImage: "chart.line.uptrend.xyaxis"
                                )
                            }

                            if let legacyLifetimeDownloads = model.importedDeckedBuilderInsights.legacyLifetimeDownloads {
                                Label(
                                    "Legacy lifetime downloads from imported analytics files: \(legacyLifetimeDownloads.formatted())",
                                    systemImage: "arrow.down.circle"
                                )
                            }

                            if let average30Day = model.importedDeckedBuilderInsights.legacyIOSActiveDevices30DayAverage {
                                Label(
                                    "Legacy iOS 30-day active-device average from imports: \(average30Day.formatted(.number.precision(.fractionLength(0))))",
                                    systemImage: "iphone"
                                )
                            }
                        }
                    }
                }

                SectionCard(
                    title: "Missing Report Checklist",
                    subtitle: "\(completedChecklistCount) of \(checklistItems.count) core report types are currently covered"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(checklistItems) { item in
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.headline)

                                    Text(item.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isComplete ? .green : .secondary)
                            }
                        }

                        Divider()

                        if let nextNeededChecklistItem {
                            Label(
                                "Next recommended import: \(nextNeededChecklistItem.title)",
                                systemImage: "arrow.right.circle.fill"
                            )
                            .font(.headline)

                            Text(nextNeededChecklistItem.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Label("Core Decked Builder imports are covered.", systemImage: "checkmark.seal.fill")
                                .font(.headline)
                                .foregroundStyle(.green)

                            Text("You can still import supporting reports like Subscriber, Subscription Event, or Win-Back exports for deeper analysis later.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Imports")
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: supportedTypes,
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                model.importReports(from: urls)
            case .failure(let error):
                model.importStatusMessage = error.localizedDescription
            }
        }
    }
}

private struct ImportChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let isComplete: Bool
}

private struct ImportedReportRow: View {
    let report: ImportedReport
    let onOpen: () -> Void
    let onReveal: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.originalFileName)
                        .font(.headline)

                    Text(report.detectedKind.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(report.importedAt, format: .dateTime.month().day().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(ByteCountFormatter.string(fromByteCount: report.fileSize, countStyle: .file)) copied into app storage")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Button("Open Copy", action: onOpen)
                Button("Reveal In Finder", action: onReveal)
                    .buttonStyle(.link)
                Button("Remove", role: .destructive, action: onDelete)
                    .buttonStyle(.link)
            }
        }
    }
}

#Preview {
    ImportsView(model: AppModel())
        .frame(width: 1100, height: 800)
}
