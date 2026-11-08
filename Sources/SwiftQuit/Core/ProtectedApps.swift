import AppKit
import Combine

@MainActor
final class ProtectedApps: ObservableObject {
    static let hardcodedDefaults: Set<String> = [
        "com.apple.finder",
        "com.apple.systempreferences",
        "com.apple.dt.Xcode",
    ]

    private let userDefaultsKey = "protectedApps"
    private let defaults: UserDefaults

    @Published private(set) var bundleIDs: Set<String>

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        let saved = Set(userDefaults.stringArray(forKey: "protectedApps") ?? [])
        self.bundleIDs = saved.union(Self.hardcodedDefaults)
    }

    func add(bundleID: String) {
        bundleIDs.insert(bundleID)
        persist()
    }

    func remove(bundleID: String) {
        guard !Self.hardcodedDefaults.contains(bundleID) else { return }
        bundleIDs.remove(bundleID)
        persist()
    }

    func contains(bundleID: String) -> Bool {
        bundleIDs.contains(bundleID)
    }

    func runningRegularApps() -> [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .filter { $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    private func persist() {
        let userAdded = bundleIDs.subtracting(Self.hardcodedDefaults)
        defaults.set(Array(userAdded), forKey: userDefaultsKey)
    }
}
