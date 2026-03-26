import SwiftUI

struct StatusContentView: View {
    @ObservedObject var monitor: StatusMonitor
    @State private var showingAddService = false

    var body: some View {
        VStack(spacing: 0) {
            if showingAddService {
                AddServiceView(monitor: monitor, onDismiss: {
                    showingAddService = false
                })
            } else {
                serviceListView
            }
        }
        .frame(width: 350)
    }

    private var serviceListView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("StatusChecker")
                    .font(.headline)

                Spacer()

                if monitor.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    Task { await monitor.refreshAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(monitor.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)

            if let lastRefresh = monitor.lastRefresh {
                HStack {
                    Text("Updated \(lastRefresh, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }

            Divider()

            // Services list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if monitor.services.isEmpty {
                        Text("No services added yet")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(monitor.services) { service in
                            ServiceSectionView(
                                service: service,
                                result: monitor.results[service.id],
                                onRemove: { monitor.removeService(id: service.id) }
                            )

                            if service.id != monitor.services.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 400)

            Divider()

            // Footer
            VStack(spacing: 4) {
                Button {
                    showingAddService = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Service")
                    }
                }
                .buttonStyle(.borderless)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit StatusChecker")
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding(.vertical, 8)
        }
    }
}
