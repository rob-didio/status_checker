import SwiftUI
import Combine

@MainActor
class StatusMonitor: ObservableObject {
    @Published var services: [MonitoredService]
    @Published var results: [UUID: Result<StatusPageSummary, Error>] = [:]
    @Published var isLoading = false
    @Published var lastRefresh: Date?

    var notificationManager: NotificationManager?

    private let client = StatusPageClient()
    private let store = ServiceStore()
    private var timerCancellable: AnyCancellable?
    private var wakeCancellable: AnyCancellable?

    var overallStatus: OverallStatusLevel {
        if results.isEmpty { return .unknown }

        var hasError = false
        var hasDegraded = false

        for (_, result) in results {
            switch result {
            case .success(let summary):
                for component in summary.components where component.group != true {
                    switch component.status {
                    case .majorOutage:
                        return .outage
                    case .partialOutage:
                        hasError = true
                    case .degradedPerformance, .underMaintenance:
                        hasDegraded = true
                    case .operational, .unknown:
                        break
                    }
                }
                if !summary.incidents.isEmpty {
                    hasDegraded = true
                }
            case .failure:
                hasError = true
            }
        }

        if hasError { return .outage }
        if hasDegraded { return .degraded }
        return .allOperational
    }

    init() {
        self.services = ServiceStore().load()
        startTimer()
        observeWake()
        Task { await refreshAll() }
    }

    func refreshAll() async {
        isLoading = true
        await withTaskGroup(of: (UUID, Result<StatusPageSummary, Error>).self) { group in
            for service in services {
                group.addTask { [client] in
                    do {
                        let summary = try await client.fetchSummary(for: service)
                        return (service.id, .success(summary))
                    } catch {
                        return (service.id, .failure(error))
                    }
                }
            }
            for await (id, result) in group {
                let oldSummary: StatusPageSummary? = {
                    if case .success(let s) = results[id] { return s }
                    return nil
                }()
                results[id] = result
                if case .success(let newSummary) = result,
                   let service = services.first(where: { $0.id == id }) {
                    notificationManager?.processChanges(service: service, old: oldSummary, new: newSummary)
                }
            }
        }
        lastRefresh = Date()
        isLoading = false
    }

    func addService(name: String, url: URL) {
        let service = MonitoredService(id: UUID(), name: name, baseURL: url)
        services.append(service)
        store.save(services)
        Task { await refreshService(service) }
    }

    func removeService(id: UUID) {
        services.removeAll { $0.id == id }
        results.removeValue(forKey: id)
        store.save(services)
        notificationManager?.removeSubscriptions(forService: id)
    }

    private func refreshService(_ service: MonitoredService) async {
        do {
            let summary = try await client.fetchSummary(for: service)
            results[service.id] = .success(summary)
        } catch {
            results[service.id] = .failure(error)
        }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.refreshAll() }
            }
    }

    private func observeWake() {
        wakeCancellable = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.refreshAll() }
            }
    }
}
