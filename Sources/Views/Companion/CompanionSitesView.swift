import SwiftUI

#if os(iOS)
struct CompanionSitesView: View {
    @Bindable var model: AppModel

    var body: some View {
        List {
            ForEach(model.snapshot.funding.siteCandidates) { candidate in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(candidate.name)
                            .font(.headline)

                        Spacer()

                        Menu {
                            ForEach(SitePipelineStatus.allCases) { status in
                                Button {
                                    model.setSitePipelineStatus(status, for: candidate)
                                } label: {
                                    Label(status.title, systemImage: status.systemImage)
                                }
                            }
                        } label: {
                            Label(
                                model.sitePipelineStatus(for: candidate).title,
                                systemImage: model.sitePipelineStatus(for: candidate).systemImage
                            )
                            .font(.subheadline.weight(.semibold))
                        }
                    }

                    Text(candidate.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Score: \(candidate.score.formatted(.number.precision(.fractionLength(1))))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Sites")
    }
}

#Preview {
    NavigationStack {
        CompanionSitesView(model: AppModel())
    }
}
#endif
