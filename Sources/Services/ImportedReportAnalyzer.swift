import Foundation

enum ImportedReportAnalyzer {
    static func analyze(_ reports: [ImportedReport], baselineMonthlyOpsCost: Double) -> ImportedDeckedBuilderInsights {
        let sortedReports = latestReportsByOriginalFileName(from: reports)
            .sorted { $0.importedAt > $1.importedAt }

        var activeSubscribers: Int?
        var sixMonthSubscribers: Int?
        var oneMonthSubscribers: Int?
        var usSubscriberShare: Double?
        var trailing12MonthProceeds: Double?
        var trailing3MonthProceeds: Double?
        var revenueSeries: [RevenuePoint] = []
        var legacyLifetimeDownloads: Int?
        var legacyIOSActiveDevices30DayAverage: Double?
        var legacyIOSActiveDevices90DayAverage: Double?
        var notes: [String] = []

        if let subscriptionReport = sortedReports.first(where: { $0.detectedKind == .subscriptionReport }),
           let metrics = parseSubscriptionReport(from: subscriptionReport.storedFileURL) {
            activeSubscribers = metrics.totalSubscribers
            sixMonthSubscribers = metrics.sixMonthSubscribers
            oneMonthSubscribers = metrics.oneMonthSubscribers
            usSubscriberShare = metrics.usSubscriberShare
            notes.append("Subscription mix is coming from \(subscriptionReport.originalFileName).")
        }

        if let salesChartReport = sortedReports.first(where: { $0.detectedKind == .appStoreSalesChart }),
           let metrics = parseSalesChart(from: salesChartReport.storedFileURL) {
            trailing12MonthProceeds = metrics.trailing12MonthAverage
            trailing3MonthProceeds = metrics.trailing3MonthAverage
            revenueSeries = metrics.revenueSeries
            notes.append("Monthly proceeds are coming from \(salesChartReport.originalFileName).")
        }

        let firstTimeDownloadReports = sortedReports.filter { $0.detectedKind == .appAnalyticsDownloads }
        if !firstTimeDownloadReports.isEmpty {
            let totalDownloads = firstTimeDownloadReports
                .compactMap { parseTimeSeries(from: $0.storedFileURL, valueColumnTitle: "First-Time Downloads") }
                .reduce(0) { partial, parsed in
                    partial + Int(parsed.values.reduce(0, +).rounded())
                }

            if totalDownloads > 0 {
                legacyLifetimeDownloads = totalDownloads
                notes.append("Legacy download totals are based on imported App Analytics first-time download exports.")
            }
        }

        if let legacyIOSActiveReport = sortedReports.first(where: {
            $0.detectedKind == .appAnalyticsActiveDevices &&
            $0.originalFileName.lowercased().contains("decked_builder (ios and visionos)")
        }) ?? sortedReports.first(where: { $0.detectedKind == .appAnalyticsActiveDevices }),
           let metrics = parseActiveDevices(from: legacyIOSActiveReport.storedFileURL) {
            legacyIOSActiveDevices30DayAverage = metrics.average30Day
            legacyIOSActiveDevices90DayAverage = metrics.average90Day
            notes.append("Legacy active-device averages are coming from \(legacyIOSActiveReport.originalFileName).")
        }

        let netMonthlySupportEstimate = trailing12MonthProceeds.map { max($0 - baselineMonthlyOpsCost, 0) }

        if sortedReports.isEmpty {
            notes.append("No imported reports yet. Import App Store Connect exports to replace seeded assumptions.")
        }

        return ImportedDeckedBuilderInsights(
            importedReportCount: reports.count,
            latestImportDate: sortedReports.first?.importedAt,
            activeSubscribers: activeSubscribers,
            sixMonthSubscribers: sixMonthSubscribers,
            oneMonthSubscribers: oneMonthSubscribers,
            usSubscriberShare: usSubscriberShare,
            trailing12MonthProceeds: trailing12MonthProceeds,
            trailing3MonthProceeds: trailing3MonthProceeds,
            netMonthlySupportEstimate: netMonthlySupportEstimate,
            revenueSeries: revenueSeries,
            legacyLifetimeDownloads: legacyLifetimeDownloads,
            legacyIOSActiveDevices30DayAverage: legacyIOSActiveDevices30DayAverage,
            legacyIOSActiveDevices90DayAverage: legacyIOSActiveDevices90DayAverage,
            notes: notes
        )
    }

    private static func parseSalesChart(from url: URL) -> SalesChartMetrics? {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        let lines = contents.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count >= 5 else { return nil }

        let header = parseCSVRow(lines[3])
        let proceedsRow = lines.dropFirst(4).map(parseCSVRow).first { row in
            row.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "Proceeds"
        }

        guard let proceedsRow, header.count == proceedsRow.count else { return nil }

        let monthPairs = zip(header.dropFirst(), proceedsRow.dropFirst())
            .compactMap { label, value -> (String, Double)? in
                guard let amount = Double(value) else { return nil }
                return (label, amount)
            }

        let nonZeroMonths = monthPairs.filter { $0.1 > 0 }
        guard !nonZeroMonths.isEmpty else { return nil }

        let trailing12 = Array(nonZeroMonths.suffix(12)).map(\.1)
        let trailing3 = Array(nonZeroMonths.suffix(3)).map(\.1)
        let series = Array(nonZeroMonths.suffix(12)).map { RevenuePoint(label: $0.0, amount: $0.1) }

        return SalesChartMetrics(
            trailing12MonthAverage: average(of: trailing12),
            trailing3MonthAverage: average(of: trailing3),
            revenueSeries: series
        )
    }

    private static func parseSubscriptionReport(from url: URL) -> SubscriptionMetrics? {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        let rows = contents.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard let headerLine = rows.first else { return nil }
        let headers = headerLine.components(separatedBy: "\t")
        let headerIndex = Dictionary(uniqueKeysWithValues: headers.enumerated().map { ($1, $0) })

        guard let subscriptionNameIndex = headerIndex["Subscription Name"],
              let countryIndex = headerIndex["Country"],
              let subscribersIndex = headerIndex["Subscribers"],
              let activeStandardIndex = headerIndex["Active Standard Price Subscriptions"] else {
            return nil
        }

        var totalSubscribers = 0
        var totalUSSubscribers = 0
        var sixMonthSubscribers = 0
        var oneMonthSubscribers = 0

        for row in rows.dropFirst() {
            let columns = row.components(separatedBy: "\t")
            guard columns.indices.contains(subscriptionNameIndex),
                  columns.indices.contains(countryIndex),
                  columns.indices.contains(subscribersIndex),
                  columns.indices.contains(activeStandardIndex) else {
                continue
            }

            let fallbackSubscriberCount = Int(columns[activeStandardIndex].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let explicitSubscriberCount = Int(columns[subscribersIndex].trimmingCharacters(in: .whitespacesAndNewlines))
            let subscriberCount = max(explicitSubscriberCount ?? 0, fallbackSubscriberCount)
            guard subscriberCount > 0 else { continue }

            totalSubscribers += subscriberCount

            if columns[countryIndex].trimmingCharacters(in: .whitespacesAndNewlines) == "US" {
                totalUSSubscribers += subscriberCount
            }

            let subscriptionName = columns[subscriptionNameIndex].lowercased()
            if subscriptionName.contains("6 month") {
                sixMonthSubscribers += subscriberCount
            } else if subscriptionName.contains("1 month") {
                oneMonthSubscribers += subscriberCount
            }
        }

        guard totalSubscribers > 0 else { return nil }

        return SubscriptionMetrics(
            totalSubscribers: totalSubscribers,
            sixMonthSubscribers: sixMonthSubscribers,
            oneMonthSubscribers: oneMonthSubscribers,
            usSubscriberShare: (Double(totalUSSubscribers) / Double(totalSubscribers)) * 100
        )
    }

    private static func parseActiveDevices(from url: URL) -> ActiveDeviceMetrics? {
        guard let parsed = parseTimeSeries(from: url, valueColumnTitle: "Active Devices") else {
            return nil
        }

        return ActiveDeviceMetrics(
            average30Day: average(of: Array(parsed.values.suffix(30))),
            average90Day: average(of: Array(parsed.values.suffix(90)))
        )
    }

    private static func parseTimeSeries(from url: URL, valueColumnTitle: String) -> ParsedTimeSeries? {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        let rows = contents.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard let headerIndex = rows.firstIndex(where: { $0.starts(with: "Date,") }) else {
            return nil
        }

        let header = parseCSVRow(rows[headerIndex])
        guard header.count >= 2, header[1] == valueColumnTitle else {
            return nil
        }

        let values = rows.dropFirst(headerIndex + 1).compactMap { row -> Double? in
            let columns = parseCSVRow(row)
            guard columns.count >= 2 else { return nil }
            return Double(columns[1])
        }

        guard !values.isEmpty else { return nil }
        return ParsedTimeSeries(values: values)
    }

    private static func parseCSVRow(_ line: String) -> [String] {
        var values: [String] = []
        var current = ""
        var isInsideQuotes = false

        for character in line {
            switch character {
            case "\"":
                isInsideQuotes.toggle()
            case "," where !isInsideQuotes:
                values.append(current)
                current.removeAll(keepingCapacity: true)
            default:
                current.append(character)
            }
        }

        values.append(current)
        return values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private static func average(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func latestReportsByOriginalFileName(from reports: [ImportedReport]) -> [ImportedReport] {
        var newestByOriginalFileName: [String: ImportedReport] = [:]

        for report in reports {
            if let existing = newestByOriginalFileName[report.originalFileName] {
                if report.importedAt > existing.importedAt {
                    newestByOriginalFileName[report.originalFileName] = report
                }
            } else {
                newestByOriginalFileName[report.originalFileName] = report
            }
        }

        return Array(newestByOriginalFileName.values)
    }
}

private struct SalesChartMetrics {
    let trailing12MonthAverage: Double
    let trailing3MonthAverage: Double
    let revenueSeries: [RevenuePoint]
}

private struct SubscriptionMetrics {
    let totalSubscribers: Int
    let sixMonthSubscribers: Int
    let oneMonthSubscribers: Int
    let usSubscriberShare: Double
}

private struct ActiveDeviceMetrics {
    let average30Day: Double
    let average90Day: Double
}

private struct ParsedTimeSeries {
    let values: [Double]
}
