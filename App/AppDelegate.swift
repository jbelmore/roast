import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var activityMonitor: ActivityMonitor?
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize database
        do {
            try DatabaseManager.shared.initialize()
        } catch {
            print("Failed to initialize database: \(error)")
        }

        // Set up menu bar
        setupMenuBar()

        // Check if onboarding is complete
        if !UserDefaults.standard.bool(forKey: "onboardingComplete") {
            showOnboarding()
        } else {
            // Start monitoring if we have permissions
            startMonitoringIfPossible()
        }

        // Set up event monitor to close popover when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let popover = self?.popover, popover.isShown {
                self?.closePopover()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Flush any pending data
        activityMonitor?.flushPendingData()

        // Remove event monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye.circle", accessibilityDescription: "Roast")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(
            rootView: MainPopoverView()
                .environmentObject(AppState.shared)
        )
    }

    @objc private func togglePopover() {
        if let popover = popover {
            if popover.isShown {
                closePopover()
            } else {
                showPopover()
            }
        }
    }

    private func showPopover() {
        if let button = statusItem?.button {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover?.contentViewController?.view.window?.makeKey()
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
    }

    private func showOnboarding() {
        let onboardingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        onboardingWindow.title = "Welcome to Roast"
        onboardingWindow.center()
        onboardingWindow.contentView = NSHostingView(
            rootView: OnboardingView(onComplete: { [weak self, weak onboardingWindow] in
                onboardingWindow?.close()
                self?.startMonitoringIfPossible()
            })
            .environmentObject(AppState.shared)
        )
        onboardingWindow.makeKeyAndOrderFront(nil)
    }

    func startMonitoringIfPossible() {
        guard UserDefaults.standard.bool(forKey: "trackingEnabled") != false else { return }

        if activityMonitor == nil {
            activityMonitor = ActivityMonitor()
        }
        activityMonitor?.startMonitoring()
        AppState.shared.isMonitoring = true
    }

    func stopMonitoring() {
        activityMonitor?.stopMonitoring()
        AppState.shared.isMonitoring = false
    }
}
