import Foundation

enum PreferencesMigration {
    /// Preserve settings from the locally installed predecessor, once only.
    static func migrate(to defaults: UserDefaults,
                        legacy: [String: Any]? = UserDefaults.standard.persistentDomain(
                            forName: "io.github.grievouz.Hush")) {
        guard !defaults.bool(forKey: "didMigrateHushPreferences") else { return }
        let keys = ["hushEnabled": "enabled", "hushQuitDelay": "quitDelay",
                    "hushNotifications": "notifications", "hushWhitelist": "protectedApps"]
        for (old, new) in keys where defaults.object(forKey: new) == nil {
            if let value = legacy?[old] { defaults.set(value, forKey: new) }
        }
        defaults.set(true, forKey: "didMigrateHushPreferences")
    }
}
