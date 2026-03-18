import SwiftUI

#if os(iOS)
struct FounderDashboardCompanionRootView: View {
    @Bindable var model: AppModel

    var body: some View {
        TabView {
            NavigationStack {
                CompanionDashboardView(model: model)
            }
            .tabItem {
                Label("Dashboard", systemImage: "rectangle.grid.2x2")
            }

            NavigationStack {
                CompanionSitesView(model: model)
            }
            .tabItem {
                Label("Sites", systemImage: "storefront")
            }

            NavigationStack {
                CompanionChecklistView(model: model)
            }
            .tabItem {
                Label("Checklist", systemImage: "checklist")
            }
        }
    }
}

#Preview {
    FounderDashboardCompanionRootView(model: AppModel())
}
#endif
