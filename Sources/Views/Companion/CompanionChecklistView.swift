import SwiftUI

#if os(iOS)
struct CompanionChecklistView: View {
    @Bindable var model: CompanionModel

    var body: some View {
        List {
            Section {
                ForEach(model.launchChecklistTasks) { task in
                    Button {
                        model.toggleLaunchChecklistTask(task)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: model.completedLaunchChecklistTaskIDs.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(model.completedLaunchChecklistTaskIDs.contains(task.id) ? .green : .secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(task.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("\(model.completedLaunchChecklistCount) of \(model.launchChecklistTasks.count) completed")
            }
        }
        .navigationTitle("Checklist")
    }
}

#Preview {
    NavigationStack {
        CompanionChecklistView(model: CompanionModel())
    }
}
#endif
