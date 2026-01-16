import AppKit
import Foundation

enum AccessibilityHelper {
    /// Check if the app has accessibility permissions
    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Request accessibility permissions
    /// This shows the system prompt and then opens System Settings for manual addition if needed
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)

        // If not trusted after the prompt, open System Settings directly
        // This helps when running as a bare executable (swift build) vs proper .app bundle
        if !trusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                openAccessibilityPreferences()
            }
        }
    }

    /// Open System Settings to the Accessibility pane
    static func openAccessibilityPreferences() {
        // macOS 13+ uses System Settings with different URL scheme
        if #available(macOS 13.0, *) {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        } else {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    /// Get the path to add to Accessibility (helpful for development)
    static var executablePath: String {
        Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments[0]
    }

    /// Check if running as a proper .app bundle
    static var isRunningAsAppBundle: Bool {
        Bundle.main.bundlePath.hasSuffix(".app")
    }

    /// Get list of all running applications
    static func getRunningApplications() -> [RunningAppInfo] {
        NSWorkspace.shared.runningApplications.compactMap { app in
            guard let bundleID = app.bundleIdentifier,
                  let name = app.localizedName,
                  app.activationPolicy == .regular else {
                return nil
            }
            return RunningAppInfo(
                bundleID: bundleID,
                name: name,
                icon: app.icon
            )
        }
    }

    /// Check if screen recording permission is granted (optional, for future use)
    /// Note: This is a simplified check - full screen recording check requires ScreenCaptureKit on macOS 12.3+
    static var hasScreenRecordingPermission: Bool {
        // Simple check by attempting to get window list
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]]
        return windowList != nil && !windowList!.isEmpty
    }
}

struct RunningAppInfo: Identifiable, Hashable {
    let id = UUID()
    let bundleID: String
    let name: String
    let icon: NSImage?

    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleID)
    }

    static func == (lhs: RunningAppInfo, rhs: RunningAppInfo) -> Bool {
        lhs.bundleID == rhs.bundleID
    }
}
