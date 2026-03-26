import Foundation
import UserNotifications

public protocol NotificationSender: Sendable {
    func send(title: String, body: String)
}

struct BundleNotificationSender: NotificationSender {
    func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

struct OsascriptNotificationSender: NotificationSender {
    func send(title: String, body: String) {
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "display notification \"\(escapedBody)\" with title \"\(escapedTitle)\""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }
}

@MainActor
public class NotificationManager: ObservableObject {
    @Published public var subscriptions: Set<NotificationSubscription>

    private let store: SubscriptionStore?
    private let sender: NotificationSender
    private var permissionGranted: Bool
    private let hasBundle: Bool

    public init() {
        let store = SubscriptionStore()
        self.store = store
        self.subscriptions = store.load()
        self.hasBundle = Bundle.main.bundleIdentifier != nil
        self.sender = Bundle.main.bundleIdentifier != nil
            ? BundleNotificationSender()
            : OsascriptNotificationSender()
        self.permissionGranted = false
    }

    public init(subscriptions: Set<NotificationSubscription> = [], sender: NotificationSender) {
        self.store = nil
        self.subscriptions = subscriptions
        self.hasBundle = false
        self.sender = sender
        self.permissionGranted = true
    }

    // MARK: - Subscription management

    public func subscribe(to scope: NotificationScope) async {
        guard await ensurePermission() else { return }
        let subscription = NotificationSubscription(scope: scope)
        subscriptions.insert(subscription)
        store?.save(subscriptions)
    }

    public func unsubscribe(from scope: NotificationScope) {
        let subscription = NotificationSubscription(scope: scope)
        subscriptions.remove(subscription)
        store?.save(subscriptions)
    }

    public func isSubscribed(to scope: NotificationScope) -> Bool {
        subscriptions.contains(NotificationSubscription(scope: scope))
    }

    public func isEffectivelySubscribed(serviceId: UUID, componentId: String) -> Bool {
        isSubscribed(to: .all)
            || isSubscribed(to: .service(serviceId: serviceId))
            || isSubscribed(to: .component(serviceId: serviceId, componentId: componentId))
    }

    public func toggleSubscription(to scope: NotificationScope) async {
        if isSubscribed(to: scope) {
            unsubscribe(from: scope)
        } else {
            await subscribe(to: scope)
        }
    }

    public func removeSubscriptions(forService serviceId: UUID) {
        subscriptions = subscriptions.filter { subscription in
            switch subscription.scope {
            case .all:
                return true
            case .service(let sid):
                return sid != serviceId
            case .component(let sid, _):
                return sid != serviceId
            }
        }
        store?.save(subscriptions)
    }

    // MARK: - Permission

    private func ensurePermission() async -> Bool {
        if permissionGranted { return true }
        if !hasBundle {
            permissionGranted = true
            return true
        }
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            permissionGranted = granted
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Change detection + notification dispatch

    public func processChanges(service: MonitoredService, old: StatusPageSummary?, new: StatusPageSummary) {
        guard let old else { return }

        let oldComponents = Dictionary(uniqueKeysWithValues: old.components.map { ($0.id, $0) })

        for component in new.components where component.group != true {
            guard let oldComponent = oldComponents[component.id],
                  oldComponent.status != component.status else { continue }

            guard isEffectivelySubscribed(serviceId: service.id, componentId: component.id) else { continue }

            sender.send(
                title: service.name,
                body: "\(component.name) is now \(component.status.displayName)"
            )
        }
    }
}
