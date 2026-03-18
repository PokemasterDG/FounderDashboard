import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded))

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension MetricCard {
    init(title: String, value: Double, format: FloatingPointFormatStyle<Double>.Currency, detail: String, systemImage: String) {
        self.init(title: title, value: value.formatted(format), detail: detail, systemImage: systemImage)
    }
}

#Preview {
    MetricCard(
        title: "Active Subscribers",
        value: "128",
        detail: "Sample subscriber count for preview purposes.",
        systemImage: "person.2.fill"
    )
    .padding()
}
