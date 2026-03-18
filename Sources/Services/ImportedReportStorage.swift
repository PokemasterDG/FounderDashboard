import Foundation

enum ImportedReportStorage {
    static var applicationSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("FounderDashboard", isDirectory: true)
    }

    static var storedReportsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("ImportedReports", isDirectory: true)
    }

    static var manifestURL: URL {
        applicationSupportDirectory.appendingPathComponent("imported_reports.json")
    }
}
