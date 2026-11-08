import SwiftUI
import AppKit

struct AppIconView: View {
    let bundleID: String
    var bundleURL: URL? = nil

    var body: some View {
        let url = bundleURL ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        if let url {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable().interpolation(.high).frame(width: 28, height: 28)
        } else {
            Image(systemName: "app").font(.title2).foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
        }
    }
}

func appDisplayName(_ bundleID: String) -> String {
    if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) {
        return app.localizedName ?? bundleID
    }
    return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)?
        .deletingPathExtension().lastPathComponent ?? bundleID
}
