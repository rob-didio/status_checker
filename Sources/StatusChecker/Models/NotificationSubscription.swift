import Foundation

public enum NotificationScope: Hashable {
    case all
    case service(serviceId: UUID)
    case component(serviceId: UUID, componentId: String)
}

extension NotificationScope: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, serviceId, componentId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .all:
            try container.encode("all", forKey: .type)
        case .service(let serviceId):
            try container.encode("service", forKey: .type)
            try container.encode(serviceId, forKey: .serviceId)
        case .component(let serviceId, let componentId):
            try container.encode("component", forKey: .type)
            try container.encode(serviceId, forKey: .serviceId)
            try container.encode(componentId, forKey: .componentId)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "all":
            self = .all
        case "service":
            let serviceId = try container.decode(UUID.self, forKey: .serviceId)
            self = .service(serviceId: serviceId)
        case "component":
            let serviceId = try container.decode(UUID.self, forKey: .serviceId)
            let componentId = try container.decode(String.self, forKey: .componentId)
            self = .component(serviceId: serviceId, componentId: componentId)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown scope type: \(type)")
        }
    }
}

public struct NotificationSubscription: Codable, Identifiable, Hashable {
    public let scope: NotificationScope

    public init(scope: NotificationScope) {
        self.scope = scope
    }

    public var id: String {
        switch scope {
        case .all:
            return "all"
        case .service(let serviceId):
            return "service:\(serviceId.uuidString)"
        case .component(let serviceId, let componentId):
            return "component:\(serviceId.uuidString):\(componentId)"
        }
    }
}
