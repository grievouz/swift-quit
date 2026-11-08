import AppKit
import Combine
import ApplicationServices

@MainActor
final class AppMonitor: ObservableObject {
    @Published private(set) var recentlyQuit: [QuitRecord] = []
    @Published private(set) var accessibilityGranted = AXIsProcessTrusted()
    @Published var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: "enabled")
            resetObservations()
        }
    }
    @Published var quitDelay: Double {
        didSet {
            defaults.set(quitDelay, forKey: "quitDelay")
            resetObservations()
        }
    }
    @Published var showNotifications: Bool {
        didSet { defaults.set(showNotifications, forKey: "notifications") }
    }

    private let defaults: UserDefaults
    private let windowChecker: WindowChecker
    private let protectedApps: ProtectedApps
    private let quitter: AppQuitter
    private var policies: [pid_t: QuitPolicy] = [:]
    private var pendingQuits: [pid_t: QuitRecord] = [:]
    private var observers: [Any] = []
    private var subscriptions: Set<AnyCancellable> = []
    private var pollTimer: Timer?
    private var scanTask: Task<Void, Never>?
    private var generation = 0
    private var suppressUntil = Date().addingTimeInterval(3)

    init(windowChecker: WindowChecker, protectedApps: ProtectedApps,
         quitter: AppQuitter, userDefaults: UserDefaults = .standard,
         startMonitoring: Bool = true) {
        self.defaults = userDefaults
        self.windowChecker = windowChecker
        self.protectedApps = protectedApps
        self.quitter = quitter
        self.isEnabled = userDefaults.object(forKey: "enabled") as? Bool ?? true
        let savedDelay = userDefaults.object(forKey: "quitDelay") as? Double ?? 2
        self.quitDelay = savedDelay.isFinite ? min(max(savedDelay, 1), 10) : 2
        self.showNotifications = userDefaults.bool(forKey: "notifications")
        guard startMonitoring else { return }
        setupObservers()
        protectedApps.$bundleIDs.dropFirst().sink { [weak self] _ in
            self?.resetObservations()
        }.store(in: &subscriptions)
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.scan() }
        }
        timer.tolerance = 0.25
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
        scan()
    }

    var statusText: String {
        if !accessibilityGranted { return "Accessibility access needed" }
        return isEnabled ? "Quitting apps after their last window closes" : "Automatic quitting is paused"
    }

    private func resetObservations() {
        generation += 1
        policies.removeAll()
    }

    private func setupObservers() {
        let center = NSWorkspace.shared.notificationCenter
        for event in [NSWorkspace.didActivateApplicationNotification,
                      NSWorkspace.didDeactivateApplicationNotification,
                      NSWorkspace.didLaunchApplicationNotification,
                      NSWorkspace.didUnhideApplicationNotification] {
            observers.append(center.addObserver(forName: event, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.scan() }
            })
        }
        for event in [NSWorkspace.activeSpaceDidChangeNotification,
                      NSWorkspace.willSleepNotification, NSWorkspace.didWakeNotification] {
            observers.append(center.addObserver(forName: event, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.resetObservations()
                    self?.suppressUntil = Date().addingTimeInterval(3)
                }
            })
        }
        observers.append(center.addObserver(forName: NSWorkspace.didTerminateApplicationNotification,
                                            object: nil, queue: .main) { [weak self] note in
            let pid = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
            Task { @MainActor in
                guard let self, let pid else { return }
                self.policies.removeValue(forKey: pid)
                if let record = self.pendingQuits.removeValue(forKey: pid) {
                    self.recentlyQuit.insert(record, at: 0)
                    self.recentlyQuit = Array(self.recentlyQuit.prefix(20))
                    if self.showNotifications { self.quitter.notify(record: record) }
                }
            }
        })
    }

    private func eligible(_ app: NSRunningApplication) -> Bool {
        guard !app.isTerminated, !app.isHidden, app.isFinishedLaunching,
              app.activationPolicy == .regular,
              let bundleID = app.bundleIdentifier,
              bundleID != Bundle.main.bundleIdentifier,
              !protectedApps.contains(bundleID: bundleID) else { return false }
        return true
    }

    /// Poll every regular app as a fallback for missing AX window-close events
    /// on newer macOS releases. AX calls run off the main actor, one scan at a time.
    func scan() {
        let trusted = AXIsProcessTrusted()
        if accessibilityGranted != trusted {
            accessibilityGranted = trusted
            resetObservations()
        }
        guard isEnabled, trusted, scanTask == nil else { return }
        let apps = NSWorkspace.shared.runningApplications.filter { eligible($0) }
        let pids = apps.map(\.processIdentifier)
        let activePIDs = Set(pids)
        policies = policies.filter { activePIDs.contains($0.key) }
        let currentGeneration = generation
        let checker = windowChecker
        scanTask = Task { [weak self] in
            let snapshots = await Task.detached(priority: .utility) {
                checker.snapshots(for: pids)
            }.value
            guard let self else { return }
            self.scanTask = nil
            guard self.generation == currentGeneration, self.isEnabled, AXIsProcessTrusted() else { return }
            for app in apps {
                guard self.eligible(app) else { continue }
                let pid = app.processIdentifier
                let now = Date()
                let oldEnough = app.launchDate.map { now.timeIntervalSince($0) >= 5 } ?? false
                var policy = self.policies[pid] ?? QuitPolicy()
                let shouldQuit = policy.observe(snapshots[pid] ?? .unknown, at: now,
                    delay: self.quitDelay, eligible: oldEnough && now >= self.suppressUntil)
                self.policies[pid] = policy
                if shouldQuit { self.confirmAndQuit(app) }
            }
        }
    }

    private func confirmAndQuit(_ app: NSRunningApplication) {
        let currentGeneration = generation
        let checker = windowChecker
        let pid = app.processIdentifier
        Task { [weak self] in
            // Other apps may have taken time to respond during the batch scan.
            // Recheck this app immediately before making a termination request.
            let snapshot = await Task.detached(priority: .utility) {
                checker.snapshots(for: [pid])[pid] ?? .unknown
            }.value
            guard let self, self.generation == currentGeneration,
                  self.policies[pid]?.requestedQuit == true,
                  self.pendingQuits[pid] == nil else { return }
            guard snapshot == .empty else {
                self.policies[pid] = QuitPolicy()
                return
            }
            self.requestQuit(app)
        }
    }

    private func requestQuit(_ app: NSRunningApplication) {
        guard eligible(app), isEnabled, AXIsProcessTrusted() else { return }
        let pid = app.processIdentifier
        let record = QuitRecord(appName: app.localizedName ?? "Unknown",
            bundleIdentifier: app.bundleIdentifier ?? "", bundleURL: app.bundleURL)
        pendingQuits[pid] = record
        if !quitter.quit(app: app) { pendingQuits.removeValue(forKey: pid) }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(15))
            if self?.pendingQuits[pid]?.id == record.id {
                self?.pendingQuits.removeValue(forKey: pid)
            }
        }
    }

    func keepApp(record: QuitRecord) {
        protectedApps.add(bundleID: record.bundleIdentifier)
    }

    func reopenApp(record: QuitRecord) {
        guard let url = record.bundleURL else { return }
        keepApp(record: record)
        NSWorkspace.shared.openApplication(at: url, configuration: .init())
    }

    func clearHistory() { recentlyQuit.removeAll() }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        observers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        observers.removeAll()
        resetObservations()
        scanTask?.cancel()
    }
}
