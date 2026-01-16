import AppKit
import Foundation
import Combine

class ActivityMonitor: ObservableObject {
    @Published var isMonitoring: Bool = false
    @Published var currentApp: String?
    @Published var currentSessionDuration: TimeInterval = 0

    private var currentSession: AppSession?
    private var previousBundleID: String?
    private var pendingVisits: [AppVisit] = []
    private var sessionTimer: Timer?
    private var flushTimer: Timer?
    private var excludedBundleIDs: Set<String> = []

    private let windowTitleCaptureEnabled: Bool

    init(windowTitleCapture: Bool = false) {
        self.windowTitleCaptureEnabled = windowTitleCapture
        loadExcludedApps()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true

        // Subscribe to app activation notifications
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidDeactivate),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil
        )

        // Start session timer for tracking current session duration
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionDuration()
        }

        // Start flush timer to periodically save pending data
        flushTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.flushPendingData()
        }

        // Capture current foreground app
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            handleAppActivation(frontApp)
        }
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        isMonitoring = false

        // Remove observers
        NSWorkspace.shared.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil
        )

        // Stop timers
        sessionTimer?.invalidate()
        sessionTimer = nil
        flushTimer?.invalidate()
        flushTimer = nil

        // End current session
        endCurrentSession()

        // Flush all pending data
        flushPendingData()
    }

    @objc private func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        handleAppActivation(app)
    }

    @objc private func appDidDeactivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        handleAppDeactivation(app)
    }

    private func handleAppActivation(_ app: NSRunningApplication) {
        guard let bundleID = app.bundleIdentifier,
              let appName = app.localizedName else { return }

        // Check if app is excluded
        if excludedBundleIDs.contains(bundleID) { return }

        // End previous session first
        endCurrentSession()

        // Start new session
        let windowTitle = windowTitleCaptureEnabled ? captureWindowTitle(for: app) : nil

        currentSession = AppSession(
            appBundleID: bundleID,
            appName: appName,
            windowTitle: windowTitle,
            startTime: Date(),
            isActiveWindow: true
        )

        currentApp = appName
        currentSessionDuration = 0
    }

    private func handleAppDeactivation(_ app: NSRunningApplication) {
        guard let bundleID = app.bundleIdentifier,
              let session = currentSession,
              session.appBundleID == bundleID else { return }

        endCurrentSession()
    }

    private func endCurrentSession() {
        guard var session = currentSession else { return }

        session.endTime = Date()
        let duration = session.duration

        // Save session to database
        do {
            try DatabaseManager.shared.saveSession(session)
        } catch {
            print("Failed to save session: \(error)")
        }

        // Create visit record
        let visit = AppVisit(
            appBundleID: session.appBundleID,
            appName: session.appName,
            timestamp: session.startTime,
            durationSeconds: duration,
            previousAppBundleID: previousBundleID
        )

        pendingVisits.append(visit)

        // Update previous bundle ID
        previousBundleID = session.appBundleID

        // Clear current session
        currentSession = nil
        currentApp = nil
        currentSessionDuration = 0
    }

    private func updateSessionDuration() {
        guard let session = currentSession else { return }
        currentSessionDuration = Date().timeIntervalSince(session.startTime)
    }

    func flushPendingData() {
        guard !pendingVisits.isEmpty else { return }

        let visitsToSave = pendingVisits
        pendingVisits = []

        for visit in visitsToSave {
            do {
                try DatabaseManager.shared.saveVisit(visit)
            } catch {
                print("Failed to save visit: \(error)")
                // Re-add to pending if save failed
                pendingVisits.append(visit)
            }
        }
    }

    private func captureWindowTitle(for app: NSRunningApplication) -> String? {
        // Requires accessibility permissions
        guard AXIsProcessTrusted() else { return nil }

        let pid = app.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)

        var windowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef)

        guard result == .success, let window = windowRef else { return nil }

        var titleRef: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(window as! AXUIElement, kAXTitleAttribute as CFString, &titleRef)

        guard titleResult == .success, let title = titleRef as? String else { return nil }

        return title
    }

    func loadExcludedApps() {
        do {
            let excludedApps = try DatabaseManager.shared.getExcludedApps()
            excludedBundleIDs = Set(excludedApps.map { $0.appBundleID })
        } catch {
            print("Failed to load excluded apps: \(error)")
        }
    }

    func addExcludedApp(bundleID: String, name: String) {
        let excludedApp = ExcludedApp(appBundleID: bundleID, appName: name)
        do {
            try DatabaseManager.shared.addExcludedApp(excludedApp)
            excludedBundleIDs.insert(bundleID)
        } catch {
            print("Failed to add excluded app: \(error)")
        }
    }

    func removeExcludedApp(bundleID: String) {
        do {
            try DatabaseManager.shared.removeExcludedApp(bundleID: bundleID)
            excludedBundleIDs.remove(bundleID)
        } catch {
            print("Failed to remove excluded app: \(error)")
        }
    }

    var todayContextSwitches: Int {
        do {
            let visits = try DatabaseManager.shared.getVisitsForDateRange(
                start: DateHelpers.startOfDay(),
                end: DateHelpers.endOfDay()
            )
            return visits.count
        } catch {
            return 0
        }
    }
}
