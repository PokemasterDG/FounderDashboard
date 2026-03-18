import SwiftUI

struct SourcesView: View {
    let generatedOn: String
    let sources: [SourceRecord]

    init(generatedOn: String, sources: [SourceRecord]) {
        self.generatedOn = generatedOn
        self.sources = sources
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sources")
                        .font(.largeTitle.weight(.bold))

                    Text("Seeded from the planning repo and local App Store Connect exports. Snapshot generated on \(generatedOn).")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    ForEach(sources) { source in
                        SectionCard(title: source.title, subtitle: source.kind) {
                            Text(source.detail)
                                .font(.body)
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Sources")
    }
}

#Preview {
    SourcesView(generatedOn: AppModel().snapshot.generatedOn, sources: AppModel().snapshot.sources)
        .frame(width: 960, height: 760)
}
