import Foundation

public struct MonitoredService: Codable, Identifiable, Hashable {
    public var id: UUID
    public var name: String
    public var baseURL: URL

    public init(id: UUID, name: String, baseURL: URL) {
        self.id = id
        self.name = name
        self.baseURL = baseURL
    }

    public var summaryURL: URL {
        baseURL.appendingPathComponent("api/v2/summary.json")
    }
}

public struct PresetService: Identifiable {
    public let id = UUID()
    public let name: String
    public let baseURL: URL

    public func toMonitoredService() -> MonitoredService {
        MonitoredService(id: UUID(), name: name, baseURL: baseURL)
    }

    public static let all: [PresetService] = [
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
