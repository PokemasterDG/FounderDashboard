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
