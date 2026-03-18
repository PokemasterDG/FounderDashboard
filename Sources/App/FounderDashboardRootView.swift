import SwiftUI

struct FounderDashboardRootView: View {
    @Bindable var model: AppModel

    var body: some View {
        NavigationSplitView {
            List(AppModel.Section.allCases, selection: $model.selectedSection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("FounderDashboard")
            .listStyle(.sidebar)
        } detail: {
            switch model.selectedSection ?? .dashboard {
            case .dashboard:
                DashboardOverviewView(snapshot: model.snapshot)
            case .deckedBuilder:
                DeckedBuilderView(snapshot: model.snapshot.deckedBuilder)
            case .lgsFunding:
                LGSFundingView(snapshot: model.snapshot.funding)
            case .imports:
                ImportsView(model: model)
            case .documents:
                DocumentsView(documents: model.snapshot.documents)
            case .sources:
                SourcesView(generatedOn: model.snapshot.generatedOn, sources: model.snapshot.sources)
            }
        }
    }
}

#Preview {
    FounderDashboardRootView(model: AppModel())
}
