import Foundation

enum ImportFocus: String, Hashable, Identifiable {
    case salesChart
    case subscriptionReport
    case legacyIOSDownloads
    case legacyIOSActiveDevices

    var id: String { rawValue }

    var title: String {
        switch self {
        case .salesChart: "Sales Chart"
        case .subscriptionReport: "Subscription Report"
        case .legacyIOSDownloads: "Legacy iOS First-Time Downloads"
        case .legacyIOSActiveDevices: "Legacy iOS Active Devices"
        }
    }
}
