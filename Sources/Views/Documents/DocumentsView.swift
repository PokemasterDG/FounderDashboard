import SwiftUI

struct DocumentsView: View {
    let documents: [PlanningDocument]

    init(documents: [PlanningDocument]) {
        self.documents = documents
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Documents")
                        .font(.largeTitle.weight(.bold))

                    Text("Open the current planning artifacts directly from the dashboard.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    ForEach(documents) { document in
                        SectionCard(title: document.title, subtitle: document.path) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(document.summary)
                                    .font(.body)

                                HStack {
                                    Button("Open Document") {
                                        DocumentOpening.open(document)
                                    }

                                    Button("Reveal In Finder") {
                                        DocumentOpening.reveal(document)
                                    }
                                    .buttonStyle(.link)
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Documents")
    }
}

#Preview {
    DocumentsView(documents: AppModel().snapshot.documents)
        .frame(width: 1100, height: 900)
}
