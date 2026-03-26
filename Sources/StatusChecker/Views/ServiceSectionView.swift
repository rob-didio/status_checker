import SwiftUI

struct ServiceSectionView: View {
    let service: MonitoredService
    let result: Result<StatusPageSummary, Error>?
    @ObservedObject var notificationManager: NotificationManager
    let onRemove: () -> Void

    @State private var isExpanded = false

    private var serviceStatus: OverallStatusLevel {
        switch result {
        case .success(let summary): return OverallStatusLevel(from: summary)
        case .failure: return .outage
        case .none: return .unknown
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed header — always visible
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))

                    Circle()
                        .fill(serviceStatus.color)
                        .frame(width: 10, height: 10)

                    Text(service.name)
                        .font(.headline)

                    Spacer()

                    Button {
                        Task { await notificationManager.toggleSubscription(to: .service(serviceId: service.id)) }
                    } label: {
                        Image(systemName: notificationManager.isSubscribed(to: .service(serviceId: service.id)) ? "bell.fill" : "bell")
                            .font(.caption)
                            .foregroundStyle(notificationManager.isSubscribed(to: .service(serviceId: service.id)) ? .blue : .secondary)
                    }
                    .buttonStyle(.borderless)

                    Text(serviceStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Open Status Page") {
                    NSWorkspace.shared.open(service.baseURL)
                }
                Button(notificationManager.isSubscribed(to: .service(serviceId: service.id))
                       ? "Unsubscribe from Notifications" : "Subscribe to Notifications") {
                    Task { await notificationManager.toggleSubscription(to: .service(serviceId: service.id)) }
                }
                Button("Remove", role: .destructive) {
                    onRemove()
                }
            }

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    switch result {
                    case .success(let summary):
                        let visibleComponents = summary.components.filter { component in
                            component.group != true && !(component.onlyShowIfDegraded && component.status == .operational)
                        }.sorted { $0.position < $1.position }

                        ForEach(visibleComponents) { component in
                            ComponentRowView(
                                component: component,
                                serviceId: service.id,
                                notificationManager: notificationManager
                            )
                        }

                        if !summary.incidents.isEmpty {
                            Divider()
                            ForEach(summary.incidents) { incident in
                                IncidentRowView(incident: incident)
                            }
                        }

                    case .failure(let error):
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                    case .none:
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .padding(.leading, 28)
                .padding(.top, 6)
            }
        }
        .padding(.vertical, 4)
    }
}
