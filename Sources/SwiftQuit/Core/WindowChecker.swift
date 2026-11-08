import AppKit
import ApplicationServices

struct WindowChecker: Sendable {
    /// Query all Spaces, including offscreen windows. Window titles and screen
    /// contents are not read, and no Screen Recording permission is requested.
    func snapshots(for pids: [pid_t]) -> [pid_t: WindowSnapshot] {
        guard AXIsProcessTrusted(),
              let serverWindows = CGWindowListCopyWindowInfo(
                [.optionAll, .excludeDesktopElements], kCGNullWindowID
              ) as? [[String: Any]] else {
            return Dictionary(uniqueKeysWithValues: pids.map { ($0, .unknown) })
        }

        let windowOwners = Set(serverWindows.compactMap { window -> pid_t? in
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
                  let owner = window[kCGWindowOwnerPID as String] as? Int,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? Double,
                  let height = bounds["Height"] as? Double,
                  width > 1, height > 1 else { return nil }
            return pid_t(owner)
        })

        return Dictionary(uniqueKeysWithValues: pids.map { pid in
            let app = AXUIElementCreateApplication(pid)
            AXUIElementSetMessagingTimeout(app, 0.3)
            var value: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value)
            guard result == .success, let windows = value as? [AXUIElement] else {
                return (pid, .unknown)
            }
            // Minimized/fullscreen windows and windows on another desktop all
            // protect the app. Window Server is an extra veto when AX misses one.
            return (pid, windows.isEmpty && !windowOwners.contains(pid) ? .empty : .open)
        })
    }
}
