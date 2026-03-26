import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    @Published var subscriptions: Set<NotificationSubscription>

    private let store = SubscriptionStore()
    private var permissionGranted = false
    private let hasBundle = Bundle.main.bundleIdentifier != nil

    init() {
        subscriptions = SubscriptionStore().load()
    }

    // MARK: - Subscription management

    func subscribe(to scope: NotificationScope) async {
        guard await ensurePermission() else { return }
        let subscription = NotificationSubscription(scope: scope)
        subscriptions.insert(subscription)
        store.save(subscriptions)
    }

    func unsubscribe(from scope: NotificationScope) {
        let subscription = NotificationSubscription(scope: scope)
        subscriptions.remove(subscription)
        store.save(subscriptions)
    }

    func isSubscribed(to scope: NotificationScope) -> Bool {
        subscriptions.contains(NotificationSubscription(scope: scope))
    }

    func isEffectivelySubscribed(serviceId: UUID, componentId: String) -> Bool {
        isSubscribed(to: .all)
            || isSubscribed(to: .service(serviceId: serviceId))
            || isSubscribed(to: .component(serviceId: serviceId, componentId: componentId))
    }

    func toggleSubscription(to scope: NotificationScope) async {
        if isSubscribed(to: scope) {
            unsubscribe(from: scope)
        } else {
            await subscribe(to: scope)
        }
    }

    func removeSubscriptions(forService serviceId: UUID) {
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
        store.save(subscriptions)
    }

    // MARK: - Permission

    private func ensurePermission() async -> Bool {
        if permissionGranted { return true }
        if !hasBundle {
            // No proper app bundle (swift run) — osascript fallback always works
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

    func processChanges(service: MonitoredService, old: StatusPageSummary?, new: StatusPageSummary) {
        guard let old else { return }

        let oldComponents = Dictionary(uniqueKeysWithValues: old.components.map { ($0.id, $0) })

        for component in new.components where component.group != true {
            guard let oldComponent = oldComponents[component.id],
                  oldComponent.status != component.status else { continue }

            guard isEffectivelySubscribed(serviceId: service.id, componentId: component.id) else { continue }

            sendNotification(
                title: service.name,
                body: "\(component.name) is now \(component.status.displayName)"
            )
        }
    }

    private func sendNotification(title: String, body: String) {
        if hasBundle {
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
        } else {
            sendViaOsascript(title: title, body: body)
        }
    }

    private func sendViaOsascript(title: String, body: String) {
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "display notification \"\(escapedBody)\" with title \"\(escapedTitle)\""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }
}
