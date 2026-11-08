import XCTest
@testable import SwiftQuit

final class QuitPolicyTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_000)

    private func sample(_ policy: inout QuitPolicy, _ snapshot: WindowSnapshot,
                        _ seconds: Double, eligible: Bool = true) -> Bool {
        policy.observe(snapshot, at: start.addingTimeInterval(seconds), delay: 2, eligible: eligible)
    }

    func testAlreadyWindowlessAppQuitsAfterTheDelay() {
        var policy = QuitPolicy()
        XCTAssertFalse(sample(&policy, .empty, 0))
        XCTAssertFalse(sample(&policy, .empty, 1))
        XCTAssertTrue(sample(&policy, .empty, 2))
    }

    func testWindowlessLaunchWaitsForGracePeriodAndThenTheFullDelay() {
        var policy = QuitPolicy()
        XCTAssertFalse(sample(&policy, .empty, 0, eligible: false))
        XCTAssertFalse(sample(&policy, .empty, 5, eligible: false))
        XCTAssertFalse(sample(&policy, .empty, 6))
        XCTAssertFalse(sample(&policy, .empty, 7))
        XCTAssertTrue(sample(&policy, .empty, 8))
    }

    func testLastWindowMustStayClosedForTheWholeDelay() {
        var policy = QuitPolicy()
        XCTAssertFalse(sample(&policy, .open, 0))
        XCTAssertFalse(sample(&policy, .empty, 1))
        XCTAssertFalse(sample(&policy, .empty, 2))
        XCTAssertTrue(sample(&policy, .empty, 3))
    }

    func testReopeningAWindowCancelsCountdown() {
        var policy = QuitPolicy()
        _ = sample(&policy, .open, 0)
        _ = sample(&policy, .empty, 1)
        XCTAssertFalse(sample(&policy, .open, 2))
        XCTAssertFalse(sample(&policy, .empty, 3))
        XCTAssertFalse(sample(&policy, .empty, 4))
        XCTAssertTrue(sample(&policy, .empty, 5))
    }

    func testAccessibilityFailureResetsCountdown() {
        var policy = QuitPolicy()
        _ = sample(&policy, .open, 0)
        _ = sample(&policy, .empty, 1)
        XCTAssertFalse(sample(&policy, .unknown, 3))
        XCTAssertFalse(sample(&policy, .empty, 4))
        XCTAssertTrue(sample(&policy, .empty, 6))
    }

    func testSpaceOrLaunchGraceResetsCountdown() {
        var policy = QuitPolicy()
        _ = sample(&policy, .open, 0)
        _ = sample(&policy, .empty, 1)
        XCTAssertFalse(sample(&policy, .empty, 4, eligible: false))
        XCTAssertFalse(sample(&policy, .empty, 5))
        XCTAssertTrue(sample(&policy, .empty, 7))
    }

    func testDeclinedQuitIsNotRequestedRepeatedly() {
        var policy = QuitPolicy()
        _ = sample(&policy, .open, 0)
        _ = sample(&policy, .empty, 1)
        XCTAssertTrue(sample(&policy, .empty, 3))
        XCTAssertFalse(sample(&policy, .empty, 6))
        XCTAssertFalse(sample(&policy, .empty, 10))
        _ = sample(&policy, .open, 11)
        _ = sample(&policy, .empty, 12)
        XCTAssertTrue(sample(&policy, .empty, 14))
    }
}
