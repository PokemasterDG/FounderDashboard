import SwiftUI

struct DataStatusCard: View {
    enum Status {
        case imported
        case seeded
        case mixed

        var title: String {
            switch self {
            case .imported: "Imported Data"
            case .seeded: "Seeded Snapshot"
            case .mixed: "Mixed Data"
            }
        }

        var systemImage: String {
            switch self {
            case .imported: "checkmark.circle.fill"
            case .seeded: "square.stack.3d.up"
            case .mixed: "arrow.triangle.branch"
            }
        }

        var tint: Color {
            switch self {
            case .imported: .green
            case .seeded: .orange
            case .mixed: .blue
            }
        }
    }

    let status: Status
    let summary: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: status.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(status.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(status.title)
                    .font(.headline)

                Text(summary)
                    .font(.subheadline.weight(.medium))

                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(status.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(status.tint.opacity(0.18), lineWidth: 1)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        DataStatusCard(
            status: .imported,
            summary: "Decked Builder metrics are currently using imported reports.",
            detail: "Subscriber mix and trailing proceeds came from your latest App Store Connect exports."
        )

        DataStatusCard(
            status: .mixed,
            summary: "Some metrics are live and some still come from the planning snapshot.",
            detail: "Import more reports to replace the remaining seeded assumptions."
        )
    }
    .padding()
}
