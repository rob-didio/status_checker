import SwiftUI

struct AddServiceView: View {
    @ObservedObject var monitor: StatusMonitor
    var onDismiss: () -> Void

    @State private var name = ""
    @State private var urlString = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var validated = false

    private var availablePresets: [PresetService] {
        let addedURLs = Set(monitor.services.map { $0.baseURL })
        return PresetService.all.filter { !addedURLs.contains($0.baseURL) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Service")
                .font(.headline)

            // Quick-add presets
            if !availablePresets.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(availablePresets) { preset in
                        Button {
                            monitor.addService(name: preset.name, url: preset.baseURL)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.secondary)
                                Text(preset.name)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                Text("Custom Service")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Custom URL form
            TextField("Service Name", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("Status Page URL", text: $urlString, prompt: Text("https://status.example.com"))
                .textFieldStyle(.roundedBorder)
                .onChange(of: urlString) { _ in
                    validated = false
                    validationError = nil
                }

            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if validated {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Valid Statuspage API detected")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                if validated {
                    Button("Add") {
                        addService()
                    }
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button("Validate") {
                        Task { await validate() }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty || urlString.isEmpty || isValidating)
                }
            }
        }
        .padding(20)
        .frame(width: 350)
    }

    private func validate() async {
        isValidating = true
        validationError = nil

        guard let url = URL(string: urlString) else {
            validationError = "Invalid URL"
            isValidating = false
            return
        }

        let service = MonitoredService(id: UUID(), name: name, baseURL: url)
        let client = StatusPageClient()

        do {
            _ = try await client.fetchSummary(for: service)
            validated = true
        } catch {
            validationError = "Could not reach Statuspage API: \(error.localizedDescription)"
        }

        isValidating = false
    }

    private func addService() {
        guard let url = URL(string: urlString) else { return }
        monitor.addService(name: name, url: url)
        onDismiss()
    }
}
