import Foundation

enum ImportedReportStore {
    static var applicationSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("FounderDashboard", isDirectory: true)
    }

    static var storedReportsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("ImportedReports", isDirectory: true)
    }

    private static var manifestURL: URL {
        applicationSupportDirectory.appendingPathComponent("imported_reports.json")
    }

    static func load() throws -> [ImportedReport] {
        try ensureDirectories()

        let manifestReports: [ImportedReport]

        if FileManager.default.fileExists(atPath: manifestURL.path()) {
            let data = try Data(contentsOf: manifestURL)
            manifestReports = try JSONDecoder().decode([ImportedReport].self, from: data)
        } else {
            manifestReports = []
        }

        let reconciledReports = try reconcileManifestReportsWithStoredFiles(manifestReports)
        if reconciledReports != manifestReports.sorted(by: { $0.importedAt > $1.importedAt }) {
            try save(reconciledReports)
        }

        return reconciledReports.sorted { $0.importedAt > $1.importedAt }
    }

    @discardableResult
    static func importFiles(from urls: [URL]) throws -> [ImportedReport] {
        try ensureDirectories()

        var existing = try load()
        var imported: [ImportedReport] = []

        for sourceURL in urls {
            let started = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if started {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            let values = try sourceURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard values.isRegularFile == true else { continue }

            let fileName = sourceURL.lastPathComponent
            let storedName = "\(UUID().uuidString)-\(fileName)"
            let destinationURL = storedReportsDirectory.appendingPathComponent(storedName)

            if FileManager.default.fileExists(atPath: destinationURL.path()) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            let report = ImportedReport(
                id: UUID(),
                originalFileName: fileName,
                storedFileName: storedName,
                importedAt: Date(),
                fileSize: Int64(values.fileSize ?? 0),
                detectedKind: detectKind(for: fileName)
            )
            existing.append(report)
            imported.append(report)
        }

        try save(existing)
        return imported.sorted { $0.importedAt > $1.importedAt }
    }

    static func delete(_ report: ImportedReport) throws {
        var reports = try load()
        reports.removeAll { $0.id == report.id }

        let fileURL = report.storedFileURL
        if FileManager.default.fileExists(atPath: fileURL.path()) {
            try FileManager.default.removeItem(at: fileURL)
        }

        try save(reports)
    }

    private static func save(_ reports: [ImportedReport]) throws {
        let data = try JSONEncoder.pretty.encode(reports.sorted { $0.importedAt > $1.importedAt })
        try data.write(to: manifestURL, options: .atomic)
    }

    private static func reconcileManifestReportsWithStoredFiles(_ manifestReports: [ImportedReport]) throws -> [ImportedReport] {
        let fileManager = FileManager.default
        let storedFileURLs = try fileManager.contentsOfDirectory(
            at: storedReportsDirectory,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey, .fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        var reportsByStoredName = Dictionary(uniqueKeysWithValues: manifestReports.map { ($0.storedFileName, $0) })

        for fileURL in storedFileURLs {
            let values = try fileURL.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey, .fileSizeKey, .isRegularFileKey])
            guard values.isRegularFile == true else { continue }

            let storedFileName = fileURL.lastPathComponent
            if reportsByStoredName[storedFileName] != nil {
                continue
            }

            let originalFileName = inferredOriginalFileName(from: storedFileName)
            let importedAt = values.creationDate ?? values.contentModificationDate ?? Date()
            let fileSize = Int64(values.fileSize ?? 0)

            reportsByStoredName[storedFileName] = ImportedReport(
                id: UUID(),
                originalFileName: originalFileName,
                storedFileName: storedFileName,
                importedAt: importedAt,
                fileSize: fileSize,
                detectedKind: detectKind(for: originalFileName)
            )
        }

        return Array(reportsByStoredName.values)
    }

    private static func inferredOriginalFileName(from storedFileName: String) -> String {
        let segments = storedFileName.split(separator: "-", maxSplits: 5, omittingEmptySubsequences: false)
        guard segments.count >= 6 else {
            return storedFileName
        }

        let possibleUUID = segments.prefix(5).joined(separator: "-")
        if UUID(uuidString: possibleUUID) != nil {
            return String(segments[5])
        }

        return storedFileName
    }

    private static func ensureDirectories() throws {
        try FileManager.default.createDirectory(at: applicationSupportDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: storedReportsDirectory, withIntermediateDirectories: true)
    }

    private static func detectKind(for fileName: String) -> ReportKind {
        let lower = fileName.lowercased()

        if lower.contains("itunes_sales_chart") { return .appStoreSalesChart }
        if lower.contains("itunes_sales_table") { return .appStoreSalesTable }
        if lower.contains("subscription_event") { return .subscriptionEventReport }
        if lower.contains("subscription_") { return .subscriptionReport }
        if lower.contains("subscriber_") { return .subscriberReport }
        if lower.contains("win_back") { return .winBackReport }
        if lower.contains("first_time_downloads") { return .appAnalyticsDownloads }
        if lower.contains("active_devices") { return .appAnalyticsActiveDevices }

        return .unknown
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var pretty: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
