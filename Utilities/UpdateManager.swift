import Foundation
import Sparkle
import AppKit

/// Manages application updates using Sparkle framework
class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()

    // Sparkle's update controller
    private var updaterController: SPUStandardUpdaterController!

    // Published properties for UI binding
    @Published var canCheckForUpdates: Bool = false
    @Published var isCheckingForUpdates: Bool = false
    @Published var lastUpdateCheck: Date?
    @Published var currentVersion: String = ""
    @Published var updateAvailable: Bool = false
    @Published var latestVersion: String?

    private override init() {
        super.init()

        // Initialize Sparkle updater controller
        // The updater will use SUFeedURL from Info.plist
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        // Get current version
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            currentVersion = version
        }

        // Load last check date
        lastUpdateCheck = UserDefaults.standard.object(forKey: "lastUpdateCheck") as? Date

        // Observe updater state
        setupObservers()
    }

    private func setupObservers() {
        // Check if we can check for updates
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    /// Check for updates manually
    func checkForUpdates() {
        isCheckingForUpdates = true
        updaterController.checkForUpdates(nil)

        // Update last check time
        lastUpdateCheck = Date()
        UserDefaults.standard.set(lastUpdateCheck, forKey: "lastUpdateCheck")

        // Reset checking state after a delay (Sparkle handles the UI)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isCheckingForUpdates = false
        }
    }

    /// Check for updates silently in background
    func checkForUpdatesInBackground() {
        updaterController.updater.checkForUpdatesInBackground()
    }

    /// Whether automatic update checks are enabled
    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set {
            updaterController.updater.automaticallyChecksForUpdates = newValue
            objectWillChange.send()
        }
    }

    /// Whether to automatically download updates
    var automaticallyDownloadsUpdates: Bool {
        get { updaterController.updater.automaticallyDownloadsUpdates }
        set {
            updaterController.updater.automaticallyDownloadsUpdates = newValue
            objectWillChange.send()
        }
    }

    /// Update check interval in seconds (default: 1 day)
    var updateCheckInterval: TimeInterval {
        get { updaterController.updater.updateCheckInterval }
        set {
            updaterController.updater.updateCheckInterval = newValue
            objectWillChange.send()
        }
    }

    /// Formatted last check time
    var lastCheckFormatted: String {
        guard let lastCheck = lastUpdateCheck else {
            return "Never"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastCheck, relativeTo: Date())
    }

    /// Build number
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Full version string (version + build)
    var fullVersionString: String {
        "\(currentVersion) (\(buildNumber))"
    }
}

// MARK: - Update Check Interval Options

enum UpdateCheckInterval: Int, CaseIterable {
    case hourly = 3600
    case daily = 86400
    case weekly = 604800
    case monthly = 2592000

    var title: String {
        switch self {
        case .hourly: return "Every Hour"
        case .daily: return "Every Day"
        case .weekly: return "Every Week"
        case .monthly: return "Every Month"
        }
    }

    var seconds: TimeInterval {
        TimeInterval(rawValue)
    }
}
