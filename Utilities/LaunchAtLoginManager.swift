import Foundation
import ServiceManagement

class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published var isEnabled: Bool {
        didSet {
            setLaunchAtLogin(enabled: isEnabled)
        }
    }

    private init() {
        // Check current status
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            // Revert the published value if it failed
            DispatchQueue.main.async {
                self.isEnabled = SMAppService.mainApp.status == .enabled
            }
        }
    }

    var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .notRegistered:
            return "Not registered"
        case .enabled:
            return "Enabled"
        case .requiresApproval:
            return "Requires approval in System Settings"
        case .notFound:
            return "App not found"
        @unknown default:
            return "Unknown"
        }
    }
}
