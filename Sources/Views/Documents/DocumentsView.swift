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

                if documents.isEmpty {
                    SectionCard(title: "No Local Documents Yet", subtitle: "Add your own planning files later") {
                        Text("The public sample app ships without private planning documents. This section becomes useful once you point the app at your own local files or add a document-mapping workflow.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                } else {
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
