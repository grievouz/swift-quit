import AppKit
import ApplicationServices

struct WindowChecker: Sendable {
    /// AX includes minimized windows and windows on other Spaces. Window Server
    /// is only a fallback for visible windows: it also retains invisible records
    /// for closed windows. Titles and screen contents are never read.
    func snapshots(for pids: [pid_t]) -> [pid_t: WindowSnapshot] {
        guard AXIsProcessTrusted(),
              let serverWindows = CGWindowListCopyWindowInfo(
                [.optionAll, .excludeDesktopElements], kCGNullWindowID
              ) as? [[String: Any]] else {
            return Dictionary(uniqueKeysWithValues: pids.map { ($0, .unknown) })
        }

        let windowOwners = Set(serverWindows.compactMap(Self.visibleWindowOwner))

        return Dictionary(uniqueKeysWithValues: pids.map { pid in
            let app = AXUIElementCreateApplication(pid)
            AXUIElementSetMessagingTimeout(app, 0.3)
            var value: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value)
            guard result == .success, let windows = value as? [AXUIElement] else {
                return (pid, .unknown)
            }
            // AX still protects minimized/fullscreen windows and other Spaces.
            return (pid, windows.isEmpty && !windowOwners.contains(pid) ? .empty : .open)
        })
    }

    static func visibleWindowOwner(_ window: [String: Any]) -> pid_t? {
        guard window[kCGWindowIsOnscreen as String] as? Bool == true,
              let alpha = window[kCGWindowAlpha as String] as? Double, alpha > 0,
              let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
              let owner = window[kCGWindowOwnerPID as String] as? Int,
              let bounds = window[kCGWindowBounds as String] as? [String: Any],
              let width = bounds["Width"] as? Double,
              let height = bounds["Height"] as? Double,
              width > 1, height > 1 else { return nil }
        return pid_t(owner)
    }
}
