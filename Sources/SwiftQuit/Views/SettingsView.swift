import SwiftUI
import AppKit
import ApplicationServices
import UserNotifications

struct SettingsView: View {
    @ObservedObject var monitor: AppMonitor
    @ObservedObject var protectedApps: ProtectedApps
    @State private var notificationError: String?

    var body: some View {
        TabView {
            general
                .tabItem { Label("General", systemImage: "gearshape") }
            ProtectedAppsView(protectedApps: protectedApps)
                .tabItem { Label("Protected Apps", systemImage: "checkmark.shield") }
            RecentlyQuitView(monitor: monitor)
                .tabItem { Label("Activity", systemImage: "clock") }
            about
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .padding(20)
        .frame(width: 580, height: 500)
    }

    private var general: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(nsImage: AppAssets.appLogo)
                        .resizable().frame(width: 52, height: 52)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swift Quit").font(.title2.bold())
                        Text(monitor.statusText).font(.callout).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 4)
            }
            Section {
                Toggle("Automatically quit apps", isOn: $monitor.isEnabled)
                Picker("Wait after the last window closes", selection: $monitor.quitDelay) {
                    ForEach([1.0, 2, 3, 5, 10], id: \.self) { seconds in
                        Text("\(Int(seconds)) \(seconds == 1 ? "second" : "seconds")").tag(seconds)
                    }
                }
            } footer: {
                Text("Apps quit normally so they can ask you to save. Hidden apps and apps with minimized windows stay open.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Section {
                LabeledContent("Accessibility") {
                    if monitor.accessibilityGranted {
                        Label("Allowed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Open System Settings…") { openAccessibilitySettings() }
                    }
                }
                LaunchAtLoginToggle()
                Toggle("Notify when an app quits", isOn: $monitor.showNotifications)
                    .onChange(of: monitor.showNotifications) { enabled in
                        if enabled { requestNotifications() }
                    }
                if let notificationError {
                    Text(notificationError).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var about: some View {
        VStack(spacing: 14) {
            Image(nsImage: AppAssets.appLogo).resizable().frame(width: 88, height: 88)
            Text("Swift Quit").font(.largeTitle.bold())
            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development")")
                .foregroundStyle(.secondary)
            Text("A quieter app switcher.")
            Link("Source Code & Feedback", destination: URL(string: "https://github.com/grievouz/swift-quit")!)
            Divider().frame(width: 220)
            Text("Based on Hush by jspw and contributors.\nApp and menu icons from Swift Quit by onebadidea and contributors.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Open Source Licenses…") {
                if let url = Bundle.main.resourceURL?.appendingPathComponent("Licenses") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openAccessibilitySettings() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, error in
            Task { @MainActor in
                if !granted {
                    monitor.showNotifications = false
                    notificationError = error?.localizedDescription ?? "Allow notifications for Swift Quit in System Settings to enable alerts."
                } else {
                    notificationError = nil
                }
            }
        }
    }
}
