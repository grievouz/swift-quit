import XCTest
@testable import SwiftQuit

final class PreferencesMigrationTests: XCTestCase {
    func testMigrationPreservesUserSettingsWithoutOverwritingNewPreferences() {
        let name = "SwiftQuitTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(5.0, forKey: "quitDelay")
        let legacy: [String: Any] = ["hushEnabled": false, "hushQuitDelay": 2.0,
                                    "hushWhitelist": ["test.protected.app"]]
        PreferencesMigration.migrate(to: defaults, legacy: legacy)
        XCTAssertFalse(defaults.bool(forKey: "enabled"))
        XCTAssertEqual(defaults.double(forKey: "quitDelay"), 5)
        XCTAssertEqual(defaults.stringArray(forKey: "protectedApps"), ["test.protected.app"])
        defaults.set(true, forKey: "enabled")
        PreferencesMigration.migrate(to: defaults, legacy: legacy)
        XCTAssertTrue(defaults.bool(forKey: "enabled"))
    }
}

final class AppAssetsTests: XCTestCase {
    func testBundledArtworkLoadsWithoutSourceTreePaths() {
        XCTAssertTrue(AppAssets.appLogo.isValid)
        XCTAssertTrue(AppAssets.menuBarIcon.isValid)
        XCTAssertTrue(AppAssets.menuBarIcon.isTemplate)
        XCTAssertEqual(AppAssets.menuBarIcon.size.width, 18)
    }
}
