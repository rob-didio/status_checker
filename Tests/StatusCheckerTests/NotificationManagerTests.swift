import XCTest
@testable import StatusCheckerLib

final class MockNotificationSender: NotificationSender, @unchecked Sendable {
    var sentNotifications: [(title: String, body: String)] = []

    func send(title: String, body: String) {
        sentNotifications.append((title: title, body: body))
    }
}

@MainActor
final class NotificationManagerTests: XCTestCase {

    private var mockSender: MockNotificationSender!
    private var manager: NotificationManager!

    override func setUp() {
        super.setUp()
        mockSender = MockNotificationSender()
        manager = NotificationManager(sender: mockSender)
    }

    // MARK: - Subscription management

    func testSubscribeAddsSubscription() async {
        await manager.subscribe(to: .all)
        XCTAssertTrue(manager.isSubscribed(to: .all))
    }

    func testUnsubscribeRemovesSubscription() async {
        await manager.subscribe(to: .all)
        manager.unsubscribe(from: .all)
        XCTAssertFalse(manager.isSubscribed(to: .all))
    }

    func testIsSubscribedReturnsFalseWhenNotSubscribed() {
        XCTAssertFalse(manager.isSubscribed(to: .all))
        XCTAssertFalse(manager.isSubscribed(to: .service(serviceId: UUID())))
    }

    func testToggleSubscribes() async {
        await manager.toggleSubscription(to: .all)
        XCTAssertTrue(manager.isSubscribed(to: .all))
    }

    func testToggleUnsubscribes() async {
        await manager.subscribe(to: .all)
        await manager.toggleSubscription(to: .all)
        XCTAssertFalse(manager.isSubscribed(to: .all))
    }

    // MARK: - Effective subscription (cascading)

    func testEffectivelySubscribedViaAll() async {
        await manager.subscribe(to: .all)
        XCTAssertTrue(manager.isEffectivelySubscribed(serviceId: UUID(), componentId: "any"))
    }

    func testEffectivelySubscribedViaService() async {
        let serviceId = UUID()
        await manager.subscribe(to: .service(serviceId: serviceId))
        XCTAssertTrue(manager.isEffectivelySubscribed(serviceId: serviceId, componentId: "any"))
    }

    func testEffectivelySubscribedViaComponent() async {
        let serviceId = UUID()
        await manager.subscribe(to: .component(serviceId: serviceId, componentId: "web"))
        XCTAssertTrue(manager.isEffectivelySubscribed(serviceId: serviceId, componentId: "web"))
        XCTAssertFalse(manager.isEffectivelySubscribed(serviceId: serviceId, componentId: "api"))
    }

    func testNotEffectivelySubscribedWhenEmpty() {
        XCTAssertFalse(manager.isEffectivelySubscribed(serviceId: UUID(), componentId: "any"))
    }

    // MARK: - Remove subscriptions for service

    func testRemoveSubscriptionsForService() async {
        let serviceA = UUID()
        let serviceB = UUID()
        await manager.subscribe(to: .all)
        await manager.subscribe(to: .service(serviceId: serviceA))
        await manager.subscribe(to: .component(serviceId: serviceA, componentId: "web"))
        await manager.subscribe(to: .service(serviceId: serviceB))

        manager.removeSubscriptions(forService: serviceA)

        XCTAssertTrue(manager.isSubscribed(to: .all))
        XCTAssertFalse(manager.isSubscribed(to: .service(serviceId: serviceA)))
        XCTAssertFalse(manager.isSubscribed(to: .component(serviceId: serviceA, componentId: "web")))
        XCTAssertTrue(manager.isSubscribed(to: .service(serviceId: serviceB)))
    }

    // MARK: - Change detection

    private func makeSummary(components: [Component]) -> StatusPageSummary {
        StatusPageSummary(
            page: PageInfo(id: "page", name: "Test", url: "https://example.com", updatedAt: "2024-01-01"),
            components: components,
            incidents: [],
            scheduledMaintenances: [],
            status: OverallStatus(indicator: "none", description: "All good")
        )
    }

    private func makeComponent(id: String = "c1", name: String = "Web", status: ComponentStatus = .operational) -> Component {
        Component(id: id, name: name, status: status, position: 1)
    }

    func testProcessChangesSkipsNilOld() async {
        let service = MonitoredService(id: UUID(), name: "Test", baseURL: URL(string: "https://example.com")!)
        await manager.subscribe(to: .all)

        let newSummary = makeSummary(components: [makeComponent(status: .majorOutage)])
        manager.processChanges(service: service, old: nil, new: newSummary)

        XCTAssertTrue(mockSender.sentNotifications.isEmpty)
    }

    func testProcessChangesDetectsStatusChange() async {
        let serviceId = UUID()
        let service = MonitoredService(id: serviceId, name: "Claude", baseURL: URL(string: "https://status.claude.com")!)
        await manager.subscribe(to: .all)

        let old = makeSummary(components: [makeComponent(id: "c1", name: "claude.ai", status: .operational)])
        let new = makeSummary(components: [makeComponent(id: "c1", name: "claude.ai", status: .degradedPerformance)])

        manager.processChanges(service: service, old: old, new: new)

        XCTAssertEqual(mockSender.sentNotifications.count, 1)
        XCTAssertEqual(mockSender.sentNotifications[0].title, "Claude")
        XCTAssertEqual(mockSender.sentNotifications[0].body, "claude.ai is now Degraded Performance")
    }

    func testProcessChangesRespectsSubscriptions() async {
        let serviceId = UUID()
        let service = MonitoredService(id: serviceId, name: "Claude", baseURL: URL(string: "https://status.claude.com")!)
        // Not subscribed to anything

        let old = makeSummary(components: [makeComponent(status: .operational)])
        let new = makeSummary(components: [makeComponent(status: .majorOutage)])

        manager.processChanges(service: service, old: old, new: new)

        XCTAssertTrue(mockSender.sentNotifications.isEmpty)
    }

    func testProcessChangesIgnoresUnchangedComponents() async {
        let service = MonitoredService(id: UUID(), name: "Test", baseURL: URL(string: "https://example.com")!)
        await manager.subscribe(to: .all)

        let summary = makeSummary(components: [makeComponent(status: .operational)])
        manager.processChanges(service: service, old: summary, new: summary)

        XCTAssertTrue(mockSender.sentNotifications.isEmpty)
    }

    func testProcessChangesIgnoresGroupComponents() async {
        let service = MonitoredService(id: UUID(), name: "Test", baseURL: URL(string: "https://example.com")!)
        await manager.subscribe(to: .all)

        let groupComponent = Component(id: "g1", name: "Group", status: .operational, position: 0, group: true)
        let old = makeSummary(components: [groupComponent])
        let newGroup = Component(id: "g1", name: "Group", status: .majorOutage, position: 0, group: true)
        let new = makeSummary(components: [newGroup])

        manager.processChanges(service: service, old: old, new: new)

        XCTAssertTrue(mockSender.sentNotifications.isEmpty)
    }

    func testProcessChangesMultipleComponentChanges() async {
        let service = MonitoredService(id: UUID(), name: "Test", baseURL: URL(string: "https://example.com")!)
        await manager.subscribe(to: .all)

        let old = makeSummary(components: [
            makeComponent(id: "c1", name: "Web", status: .operational),
            makeComponent(id: "c2", name: "API", status: .operational),
        ])
        let new = makeSummary(components: [
            makeComponent(id: "c1", name: "Web", status: .degradedPerformance),
            makeComponent(id: "c2", name: "API", status: .majorOutage),
        ])

        manager.processChanges(service: service, old: old, new: new)

        XCTAssertEqual(mockSender.sentNotifications.count, 2)
    }

    func testProcessChangesComponentSubscriptionOnly() async {
        let serviceId = UUID()
        let service = MonitoredService(id: serviceId, name: "Test", baseURL: URL(string: "https://example.com")!)
        await manager.subscribe(to: .component(serviceId: serviceId, componentId: "c2"))

        let old = makeSummary(components: [
            makeComponent(id: "c1", name: "Web", status: .operational),
            makeComponent(id: "c2", name: "API", status: .operational),
        ])
        let new = makeSummary(components: [
            makeComponent(id: "c1", name: "Web", status: .majorOutage),
            makeComponent(id: "c2", name: "API", status: .degradedPerformance),
        ])

        manager.processChanges(service: service, old: old, new: new)

        XCTAssertEqual(mockSender.sentNotifications.count, 1)
        XCTAssertEqual(mockSender.sentNotifications[0].body, "API is now Degraded Performance")
    }
}
