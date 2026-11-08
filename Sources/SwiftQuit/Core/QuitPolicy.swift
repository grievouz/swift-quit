import Foundation

enum WindowSnapshot: Equatable, Sendable {
    case open
    case empty
    case unknown
}

/// A quit requires an observed window followed by continuously successful,
/// empty observations. Unavailable AX data is never evidence of a closed window.
struct QuitPolicy {
    private(set) var sawWindow = false
    private(set) var emptySince: Date?
    private(set) var requestedQuit = false

    mutating func observe(_ snapshot: WindowSnapshot, at now: Date,
                          delay: TimeInterval, eligible: Bool) -> Bool {
        if snapshot == .open {
            sawWindow = true
            emptySince = nil
            requestedQuit = false
            return false
        }
        guard eligible, snapshot == .empty, sawWindow, !requestedQuit else {
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
