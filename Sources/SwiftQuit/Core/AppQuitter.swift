import AppKit
import UserNotifications

@MainActor
final class AppQuitter {
    func quit(app: NSRunningApplication) -> Bool {
        appLog("Requesting normal quit: \(app.localizedName ?? "Unknown") (pid \(app.processIdentifier))")
        return app.terminate()
    }

    func notify(record: QuitRecord) {
        let content = UNMutableNotificationContent()
        content.title = "Swift Quit"
        content.body = "\(record.appName) quit after its last window closed."
        content.interruptionLevel = .passive
        UNUserNotificationCenter.current().add(UNNotificationRequest(
            identifier: record.id.uuidString, content: content, trigger: nil
        ))
    }
}
