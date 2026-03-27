import Foundation

struct SubscriptionStore {
    private let key = "notificationSubscriptions"

    func load() -> Set<NotificationSubscription> {
        guard let data = UserDefaults.standard.data(forKey: key),
              let subscriptions = try? JSONDecoder().decode(Set<NotificationSubscription>.self, from: data) else {
            return []
        }
        return subscriptions
    }

    func save(_ subscriptions: Set<NotificationSubscription>) {
        if let data = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
