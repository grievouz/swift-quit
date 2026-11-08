import XCTest
@testable import SwiftQuit

final class ProtectedAppsTests: XCTestCase {
    @MainActor
    func testUserProtectionPersistsAndBuiltInProtectionCannotBeRemoved() {
        let name = "SwiftQuitTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let manager = ProtectedApps(userDefaults: defaults)
        manager.add(bundleID: "test.example.app")
        manager.remove(bundleID: "com.apple.finder")
        let restored = ProtectedApps(userDefaults: defaults)
        XCTAssertTrue(restored.contains(bundleID: "test.example.app"))
        XCTAssertTrue(restored.contains(bundleID: "com.apple.finder"))
        restored.remove(bundleID: "test.example.app")
        XCTAssertFalse(ProtectedApps(userDefaults: defaults).contains(bundleID: "test.example.app"))
    }
}
