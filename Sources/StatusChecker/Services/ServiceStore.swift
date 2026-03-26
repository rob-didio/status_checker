import Foundation

struct ServiceStore {
    private let key = "monitoredServices"

    func load() -> [MonitoredService] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let services = try? JSONDecoder().decode([MonitoredService].self, from: data) else {
            return []
        }
        return services
    }

    func save(_ services: [MonitoredService]) {
        if let data = try? JSONEncoder().encode(services) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
