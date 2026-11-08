import SwiftUI
import ServiceManagement

struct LaunchAtLoginToggle: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isEnabled = SMAppService.mainApp.status == .enabled
    @State private var errorMessage: String?

    var body: some View {
        Toggle("Open at login", isOn: Binding(get: { isEnabled }, set: setLaunchAtLogin))
            .onChange(of: scenePhase) { _ in refresh() }
            .onAppear { refresh() }
        if SMAppService.mainApp.status == .requiresApproval {
            Button("Allow Swift Quit in Login Items…") { SMAppService.openSystemSettingsLoginItems() }
        }
        if let errorMessage {
            Text(errorMessage).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func refresh() { isEnabled = SMAppService.mainApp.status == .enabled }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            errorMessage = nil
        } catch {
            errorMessage = "Couldn’t change Open at Login: \(error.localizedDescription)"
        }
        refresh()
    }
}
