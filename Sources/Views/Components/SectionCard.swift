import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
    }
}

#Preview {
    SectionCard(title: "Current Recommendation", subtitle: "Seeded from the planning repo") {
        Text("Keep the launch practical and protect runway.")
    }
    .padding()
}
