import SwiftUI

// MARK: - API Response Types

public struct StatusPageSummary: Codable {
    public let page: PageInfo
    public let components: [Component]
    public let incidents: [Incident]
    public let scheduledMaintenances: [Incident]
    public let status: OverallStatus

    public init(page: PageInfo, components: [Component], incidents: [Incident], scheduledMaintenances: [Incident], status: OverallStatus) {
        self.page = page
        self.components = components
        self.incidents = incidents
        self.scheduledMaintenances = scheduledMaintenances
        self.status = status
    }
}

public struct PageInfo: Codable {
    public let id: String
    public let name: String
    public let url: String
    public let updatedAt: String

    public init(id: String, name: String, url: String, updatedAt: String) {
        self.id = id
        self.name = name
        self.url = url
        self.updatedAt = updatedAt
    }
}

public struct Component: Codable, Identifiable {
    public let id: String
    public let name: String
    public let status: ComponentStatus
    public let position: Int
    public let description: String?
    public let onlyShowIfDegraded: Bool
    public let showcase: Bool?
    public let groupId: String?
    public let group: Bool?

    public init(id: String, name: String, status: ComponentStatus, position: Int, description: String? = nil, onlyShowIfDegraded: Bool = false, showcase: Bool? = nil, groupId: String? = nil, group: Bool? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.position = position
        self.description = description
        self.onlyShowIfDegraded = onlyShowIfDegraded
        self.showcase = showcase
        self.groupId = groupId
        self.group = group
    }
}

public struct Incident: Codable, Identifiable {
    public let id: String
    public let name: String
    public let status: String
    public let impact: String
    public let shortlink: String?
    public let startedAt: String?
    public let incidentUpdates: [IncidentUpdate]

    public init(id: String, name: String, status: String, impact: String, shortlink: String? = nil, startedAt: String? = nil, incidentUpdates: [IncidentUpdate] = []) {
        self.id = id
        self.name = name
        self.status = status
        self.impact = impact
        self.shortlink = shortlink
        self.startedAt = startedAt
        self.incidentUpdates = incidentUpdates
    }
}

public struct IncidentUpdate: Codable, Identifiable {
    public let id: String
    public let status: String
    public let body: String
    public let displayAt: String?
    public let updatedAt: String?

    public init(id: String, status: String, body: String, displayAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.status = status
        self.body = body
        self.displayAt = displayAt
        self.updatedAt = updatedAt
    }
}

public struct OverallStatus: Codable {
    public let indicator: String
    public let description: String

    public init(indicator: String, description: String) {
        self.indicator = indicator
        self.description = description
    }
}

// MARK: - Component Status Enum

public enum ComponentStatus: String, Codable {
    case operational
    case degradedPerformance = "degraded_performance"
    case partialOutage = "partial_outage"
    case majorOutage = "major_outage"
    case underMaintenance = "under_maintenance"
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ComponentStatus(rawValue: rawValue) ?? .unknown
    }

    public var color: Color {
        switch self {
        case .operational: return .green
        case .degradedPerformance: return .yellow
        case .partialOutage: return .orange
        case .majorOutage: return .red
        case .underMaintenance: return .blue
        case .unknown: return .secondary
        }
    }

    public var displayName: String {
        switch self {
        case .operational: return "Operational"
        case .degradedPerformance: return "Degraded Performance"
        case .partialOutage: return "Partial Outage"
        case .majorOutage: return "Major Outage"
        case .underMaintenance: return "Under Maintenance"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Overall Status Level

public enum OverallStatusLevel {
    case allOperational
    case degraded
    case outage
    case unknown

    public var symbolName: String {
        switch self {
        case .allOperational: return "checkmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .outage: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    public var color: Color {
        switch self {
        case .allOperational: return .green
        case .degraded: return .yellow
        case .outage: return .red
        case .unknown: return .secondary
        }
    }

    public var accessibilityLabel: String {
        switch self {
        case .allOperational: return "All systems operational"
        case .degraded: return "Some services degraded"
        case .outage: return "Service outage"
        case .unknown: return "Status unknown"
        }
    }

    public var label: String {
        switch self {
        case .allOperational: return "Operational"
        case .degraded: return "Degraded"
        case .outage: return "Outage"
        case .unknown: return "Unknown"
        }
    }

    public init(from summary: StatusPageSummary) {
        let components = summary.components.filter { $0.group != true }
        if components.contains(where: { $0.status == .majorOutage }) {
            self = .outage
        } else if components.contains(where: { $0.status == .partialOutage }) {
            self = .outage
        } else if components.contains(where: {
            $0.status == .degradedPerformance || $0.status == .underMaintenance
        }) || !summary.incidents.isEmpty {
            self = .degraded
        } else {
            self = .allOperational
        }
    }
}
