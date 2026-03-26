import Foundation

struct MonitoredService: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var baseURL: URL

    var summaryURL: URL {
        baseURL.appendingPathComponent("api/v2/summary.json")
    }
}

struct PresetService: Identifiable {
    let id = UUID()
    let name: String
    let baseURL: URL

    func toMonitoredService() -> MonitoredService {
        MonitoredService(id: UUID(), name: name, baseURL: baseURL)
    }

    static let all: [PresetService] = [
        PresetService(name: "Claude", baseURL: URL(string: "https://status.claude.com")!),
        PresetService(name: "GitHub", baseURL: URL(string: "https://www.githubstatus.com")!),
        PresetService(name: "Datadog", baseURL: URL(string: "https://status.datadoghq.com")!),
        PresetService(name: "Cloudflare", baseURL: URL(string: "https://www.cloudflarestatus.com")!),
        PresetService(name: "OpenAI", baseURL: URL(string: "https://status.openai.com")!),
        PresetService(name: "Vercel", baseURL: URL(string: "https://www.vercel-status.com")!),
        PresetService(name: "Netlify", baseURL: URL(string: "https://www.netlifystatus.com")!),
        PresetService(name: "Twilio", baseURL: URL(string: "https://status.twilio.com")!),
    ]
}
