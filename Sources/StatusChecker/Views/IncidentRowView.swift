import SwiftUI

struct IncidentRowView: View {
    let incident: Incident

    private var impactColor: Color {
        switch incident.impact {
        case "critical": return .red
        case "major": return .orange
        case "minor": return .yellow
        default: return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(impactColor)
                    .font(.caption)

                Text(incident.name)
                    .font(.callout)
                    .fontWeight(.medium)
            }

            if let latestUpdate = incident.incidentUpdates.first {
                Text(latestUpdate.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .onTapGesture {
            if let link = incident.shortlink, let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
