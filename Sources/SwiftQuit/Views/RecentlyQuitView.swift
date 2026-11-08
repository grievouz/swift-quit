import SwiftUI
import AppKit

struct RecentlyQuitView: View {
    @ObservedObject var monitor: AppMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recently Quit").font(.headline)
                Spacer()
                Button("Clear") { monitor.clearHistory() }
                    .disabled(monitor.recentlyQuit.isEmpty)
            }
            Text("Apps Swift Quit has quit during this session.")
                .font(.callout).foregroundStyle(.secondary)
            if monitor.recentlyQuit.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock").font(.system(size: 36)).foregroundStyle(.tertiary)
                    Text("No apps quit yet").font(.headline)
                    Text("When you close an app’s last window, it will appear here.")
                        .foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(monitor.recentlyQuit) { record in
                    HStack(spacing: 10) {
                        AppIconView(bundleID: record.bundleIdentifier, bundleURL: record.bundleURL)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(record.appName)
                            Text(record.quitDate, style: .relative).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Keep Running") { monitor.keepApp(record: record) }
                            .help("Add \(record.appName) to Protected Apps")
                        Button("Reopen") { monitor.reopenApp(record: record) }
                            .disabled(record.bundleURL == nil)
                            .help("Reopen \(record.appName) and protect it from automatic quitting")
                    }.padding(.vertical, 4)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }.padding(16)
    }
}
