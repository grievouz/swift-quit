import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private let monitor: AppMonitor
    private let protectedApps: ProtectedApps

    init(monitor: AppMonitor, protectedApps: ProtectedApps) {
        self.monitor = monitor
        self.protectedApps = protectedApps
    }

    func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = AppAssets.menuBarIcon
        item.button?.toolTip = "Swift Quit"
        item.button?.setAccessibilityLabel("Swift Quit")
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
        setupMainMenu()
    }

    private func setupMainMenu() {
        let bar = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "Swift Quit")
        add("Settings…", action: #selector(showSettings), key: ",", to: appMenu)
        appMenu.addItem(.separator())
        let hide = NSMenuItem(title: "Hide Swift Quit", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(hide)
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        add("Quit Swift Quit", action: #selector(quitApp), key: "q", to: appMenu)
        appItem.submenu = appMenu
        bar.addItem(appItem)

        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        for (title, selector, key) in [("Undo", "undo:", "z"), ("Redo", "redo:", "Z"),
                                       ("Cut", "cut:", "x"), ("Copy", "copy:", "c"),
                                       ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            edit.addItem(NSMenuItem(title: title, action: Selector(selector), keyEquivalent: key))
        }
        editItem.submenu = edit
        bar.addItem(editItem)
        NSApp.mainMenu = bar
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let status = NSMenuItem(title: monitor.statusText, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())
        let toggle = add("Automatically Quit Apps", action: #selector(toggleEnabled), to: menu)
        toggle.state = monitor.isEnabled ? .on : .off
        add("Settings…", action: #selector(showSettings), key: ",", to: menu)
        menu.addItem(.separator())
        add("Quit Swift Quit", action: #selector(quitApp), key: "q", to: menu)
    }

    @discardableResult
    private func add(_ title: String, action: Selector, key: String = "", to menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
        return item
    }

    @objc private func toggleEnabled() { monitor.isEnabled.toggle() }
    @objc private func quitApp() { NSApp.terminate(nil) }

    @objc func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 580, height: 500),
                styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "Swift Quit Settings"
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView:
                SettingsView(monitor: monitor, protectedApps: protectedApps))
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
