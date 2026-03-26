import XCTest
@testable import StatusCheckerLib

final class NotificationSubscriptionTests: XCTestCase {

    // MARK: - Codable round-trips

    func testCodableRoundTripAll() throws {
        let original = NotificationSubscription(scope: .all)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NotificationSubscription.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testCodableRoundTripService() throws {
        let uuid = UUID()
        let original = NotificationSubscription(scope: .service(serviceId: uuid))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NotificationSubscription.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testCodableRoundTripComponent() throws {
        let uuid = UUID()
        let original = NotificationSubscription(scope: .component(serviceId: uuid, componentId: "comp-1"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NotificationSubscription.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testCodableRoundTripSet() throws {
        let uuid = UUID()
        let original: Set<NotificationSubscription> = [
            NotificationSubscription(scope: .all),
            NotificationSubscription(scope: .service(serviceId: uuid)),
            NotificationSubscription(scope: .component(serviceId: uuid, componentId: "c1")),
        ]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Set<NotificationSubscription>.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testDecodingUnknownTypeThrows() {
        let json = #"{"type":"invalid","serviceId":"00000000-0000-0000-0000-000000000000"}"#
        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(NotificationScope.self, from: data))
    }

    // MARK: - ID generation

    func testIdAll() {
        let sub = NotificationSubscription(scope: .all)
        XCTAssertEqual(sub.id, "all")
    }

    func testIdService() {
        let uuid = UUID()
        let sub = NotificationSubscription(scope: .service(serviceId: uuid))
        XCTAssertEqual(sub.id, "service:\(uuid.uuidString)")
    }

    func testIdComponent() {
        let uuid = UUID()
        let sub = NotificationSubscription(scope: .component(serviceId: uuid, componentId: "web"))
        XCTAssertEqual(sub.id, "component:\(uuid.uuidString):web")
    }

    func testDifferentScopesProduceDifferentIds() {
        let uuid = UUID()
        let ids: Set<String> = [
            NotificationSubscription(scope: .all).id,
            NotificationSubscription(scope: .service(serviceId: uuid)).id,
            NotificationSubscription(scope: .component(serviceId: uuid, componentId: "c1")).id,
        ]
        XCTAssertEqual(ids.count, 3)
    }

    // MARK: - Equality

    func testSameScopeIsEqual() {
        let uuid = UUID()
        let a = NotificationSubscription(scope: .service(serviceId: uuid))
        let b = NotificationSubscription(scope: .service(serviceId: uuid))
        XCTAssertEqual(a, b)
    }

    func testDifferentScopeIsNotEqual() {
        let a = NotificationSubscription(scope: .all)
        let b = NotificationSubscription(scope: .service(serviceId: UUID()))
        XCTAssertNotEqual(a, b)
    }
}
