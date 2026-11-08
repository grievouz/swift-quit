import CoreGraphics
import XCTest
@testable import SwiftQuit

final class WindowCheckerTests: XCTestCase {
    private func record(onScreen: Bool? = nil, alpha: Double = 1,
                        layer: Int = 0) -> [String: Any] {
        var record: [String: Any] = [
            kCGWindowOwnerPID as String: 123,
            kCGWindowLayer as String: layer,
            kCGWindowAlpha as String: alpha,
            kCGWindowBounds as String: ["Width": 889.0, "Height": 448.0],
        ]
        if let onScreen { record[kCGWindowIsOnscreen as String] = onScreen }
        return record
    }

    func testRetainedClosedWindowRecordsDoNotKeepTheAppRunning() {
        // TextEdit and Preview retain full-size layer-zero records with no
        // on-screen key, including a transparent record for the closed picker.
        XCTAssertNil(WindowChecker.visibleWindowOwner(record()))
        XCTAssertNil(WindowChecker.visibleWindowOwner(record(alpha: 0)))
        XCTAssertNil(WindowChecker.visibleWindowOwner(record(onScreen: false)))
    }

    func testVisibleApplicationWindowStillVetoesQuit() {
        XCTAssertEqual(WindowChecker.visibleWindowOwner(record(onScreen: true)), 123)
    }

    func testTransparentAndOverlayWindowsDoNotVetoQuit() {
        XCTAssertNil(WindowChecker.visibleWindowOwner(record(onScreen: true, alpha: 0)))
        XCTAssertNil(WindowChecker.visibleWindowOwner(record(onScreen: true, layer: 25)))
    }
}
