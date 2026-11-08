import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ProtectedAppsView: View {
    @ObservedObject var protectedApps: ProtectedApps
    @State private var showingAddSheet = false

    private var entries: [String] {
        protectedApps.bundleIDs.sorted {
            appDisplayName($0).localizedStandardCompare(appDisplayName($1)) == .orderedAscending
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Protected Apps").font(.headline)
            Text("These apps stay running after their last window closes.")
                .font(.callout).foregroundStyle(.secondary)
            List(entries, id: \.self) { bundleID in
                HStack(spacing: 10) {
                    AppIconView(bundleID: bundleID)
                    Text(appDisplayName(bundleID)).lineLimit(1)
                    Spacer()
                    if ProtectedApps.hardcodedDefaults.contains(bundleID) {
                        Image(systemName: "lock.fill").foregroundStyle(.secondary)
                            .help("Always protected")
                            .accessibilityLabel("Always protected")
                    } else {
                        Button { protectedApps.remove(bundleID: bundleID) } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove \(appDisplayName(bundleID)) from Protected Apps")
                        .accessibilityLabel("Remove \(appDisplayName(bundleID))")
                    }
                }.padding(.vertical, 4)
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            HStack {
                Button { showingAddSheet = true } label: { Label("Add App…", systemImage: "plus") }
                Spacer()
                Text("Finder, System Settings, and Xcode are always protected.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .sheet(isPresented: $showingAddSheet) {
            AddProtectedAppSheet(protectedApps: protectedApps)
        }
    }
}

struct AddProtectedAppSheet: View {
    @ObservedObject var protectedApps: ProtectedApps
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var selection: String?

    private var candidates: [NSRunningApplication] {
        protectedApps.runningRegularApps().filter {
            guard let id = $0.bundleIdentifier else { return false }
            return !protectedApps.contains(bundleID: id) &&
                (search.isEmpty || ($0.localizedName ?? id).localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Protect an App").font(.title2.bold())
            Text("Choose a running app, or browse your Applications folder.")
                .foregroundStyle(.secondary)
            TextField("Search running apps", text: $search)
                .textFieldStyle(.roundedBorder)
            List(candidates, id: \.bundleIdentifier, selection: $selection) { app in
                HStack(spacing: 10) {
                    AppIconView(bundleID: app.bundleIdentifier ?? "")
                    Text(app.localizedName ?? app.bundleIdentifier ?? "Unknown")
                }.padding(.vertical, 3)
                    .tag(app.bundleIdentifier ?? "")
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            HStack {
                Button("Choose Application…") { chooseApplication() }
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Add") {
                    if let selection { protectedApps.add(bundleID: selection) }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selection == nil)
            }
        }.padding(24).frame(width: 460, height: 400)
    }

    private func chooseApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Protect App"
        panel.begin { response in
            guard response == .OK, let url = panel.url,
                  let id = Bundle(url: url)?.bundleIdentifier else { return }
            protectedApps.add(bundleID: id)
            dismiss()
        }
    }
}
