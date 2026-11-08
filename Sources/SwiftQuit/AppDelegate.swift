import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var appMonitor: AppMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.start()
        NSApp.setActivationPolicy(.accessory)
        // UI review mode never monitors or quits other apps, requests permissions,
        // or writes the user's preferences.
        let preview = ProcessInfo.processInfo.arguments.contains("--preview-ui")
        let defaults = preview ? UserDefaults(suiteName: "io.github.grievouz.SwiftQuit.preview")! : .standard
        if !preview { PreferencesMigration.migrate(to: defaults) }
        let protectedApps = ProtectedApps(userDefaults: defaults)
        let monitor = AppMonitor(windowChecker: WindowChecker(), protectedApps: protectedApps,
            quitter: AppQuitter(), userDefaults: defaults, startMonitoring: !preview)
        appMonitor = monitor
        let controller = MenuBarController(monitor: monitor, protectedApps: protectedApps)
        menuBarController = controller
        controller.setup()
        if preview || !monitor.accessibilityGranted { controller.showSettings() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        menuBarController?.showSettings()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) { appMonitor?.stop() }
}
