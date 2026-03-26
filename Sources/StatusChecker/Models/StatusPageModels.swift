import SwiftUI

// MARK: - API Response Types

struct StatusPageSummary: Codable {
    let page: PageInfo
    let components: [Component]
    let incidents: [Incident]
    let scheduledMaintenances: [Incident]
    let status: OverallStatus
}

struct PageInfo: Codable {
    let id: String
    let name: String
    let url: String
    let updatedAt: String
}

struct Component: Codable, Identifiable {
    let id: String
    let name: String
    let status: ComponentStatus
    let position: Int
    let description: String?
    let onlyShowIfDegraded: Bool
    let showcase: Bool?
    let groupId: String?
    let group: Bool?
}

struct Incident: Codable, Identifiable {
    let id: String
    let name: String
    let status: String
    let impact: String
    let shortlink: String?
    let startedAt: String?
    let incidentUpdates: [IncidentUpdate]
}

struct IncidentUpdate: Codable, Identifiable {
    let id: String
    let status: String
    let body: String
    let displayAt: String?
    let updatedAt: String?
}

struct OverallStatus: Codable {
    let indicator: String
    let description: String
}

// MARK: - Component Status Enum

enum ComponentStatus: String, Codable {
    case operational
    case degradedPerformance = "degraded_performance"
    case partialOutage = "partial_outage"
    case majorOutage = "major_outage"
    case underMaintenance = "under_maintenance"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ComponentStatus(rawValue: rawValue) ?? .unknown
    }

    var color: Color {
        switch self {
        case .operational: return .green
        case .degradedPerformance: return .yellow
        case .partialOutage: return .orange
        case .majorOutage: return .red
        case .underMaintenance: return .blue
        case .unknown: return .secondary
        }
    }

    var displayName: String {
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

enum OverallStatusLevel {
    case allOperational
    case degraded
    case outage
    case unknown

    var symbolName: String {
        switch self {
        case .allOperational: return "checkmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .outage: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .allOperational: return .green
        case .degraded: return .yellow
        case .outage: return .red
        case .unknown: return .secondary
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .allOperational: return "All systems operational"
        case .degraded: return "Some services degraded"
        case .outage: return "Service outage"
        case .unknown: return "Status unknown"
        }
    }

    var label: String {
        switch self {
        case .allOperational: return "Operational"
        case .degraded: return "Degraded"
        case .outage: return "Outage"
        case .unknown: return "Unknown"
        }
    }

    init(from summary: StatusPageSummary) {
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
