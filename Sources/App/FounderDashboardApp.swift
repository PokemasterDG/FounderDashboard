import SwiftUI

@main
struct FounderDashboardApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            FounderDashboardRootView(model: model)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1320, height: 860)
    }
}
