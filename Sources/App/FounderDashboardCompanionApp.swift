import SwiftUI

#if os(iOS)
@main
struct FounderDashboardCompanionApp: App {
    @State private var model = CompanionModel()

    var body: some Scene {
        WindowGroup {
            FounderDashboardCompanionRootView(model: model)
        }
    }
}
#endif
