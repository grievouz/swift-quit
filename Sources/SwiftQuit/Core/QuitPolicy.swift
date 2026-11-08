import Foundation

enum WindowSnapshot: Equatable, Sendable {
    case open
    case empty
    case unknown
}

/// A quit requires continuously successful, empty observations after the launch
/// grace period. Unavailable AX data is never evidence of a closed window.
struct QuitPolicy {
    private(set) var emptySince: Date?
    private(set) var requestedQuit = false

    mutating func observe(_ snapshot: WindowSnapshot, at now: Date,
                          delay: TimeInterval, eligible: Bool) -> Bool {
        if snapshot == .open {
            emptySince = nil
            requestedQuit = false
            return false
        }
        guard eligible, snapshot == .empty, !requestedQuit else {
            emptySince = nil
            return false
        }
        guard let since = emptySince else {
            emptySince = now
            return false
        }
        guard now.timeIntervalSince(since) >= delay else { return false }
        requestedQuit = true
        return true
    }
}
