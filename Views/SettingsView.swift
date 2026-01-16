import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var launchAtLogin = LaunchAtLoginManager.shared
    @State private var apiKey: String = ""
    @State private var isAPIKeyVisible = false
    @State private var trackingEnabled = true
    @State private var windowTitleCapture = false
    @State private var defaultPersonality: ReportPersonality = .roast
    @State private var excludedApps: [ExcludedApp] = []
    @State private var runningApps: [RunningAppInfo] = []
    @State private var showExportConfirmation = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // API Key Section
                SettingsSection(title: "Claude API Key") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if isAPIKeyVisible {
                                TextField("sk-ant-...", text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                SecureField("sk-ant-...", text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Button(action: { isAPIKeyVisible.toggle() }) {
                                Image(systemName: isAPIKeyVisible ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.plain)

                            Button("Save") {
                                saveAPIKey()
                            }
                            .disabled(apiKey.isEmpty)
                        }

                        HStack(spacing: 4) {
                            if appState.apiKeyConfigured {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("API key configured")
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                                Text("API key not set")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.caption)

                        Link("Get an API key from Anthropic",
                             destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                            .font(.caption)
                    }
                }

                // Report Personality Section
                SettingsSection(title: "Report Personality") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose your default feedback style:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(ReportPersonality.allCases, id: \.self) { personality in
                            PersonalityOption(
                                personality: personality,
                                isSelected: defaultPersonality == personality,
                                onSelect: {
                                    defaultPersonality = personality
                                    UserDefaults.standard.set(personality.rawValue, forKey: "defaultPersonality")
                                }
                            )
                        }
                    }
                }

                // Tracking Section
                SettingsSection(title: "Tracking") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable activity monitoring", isOn: $trackingEnabled)
                            .onChange(of: trackingEnabled) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "trackingEnabled")
                                if newValue {
                                    (NSApp.delegate as? AppDelegate)?.startMonitoringIfPossible()
                                } else {
                                    (NSApp.delegate as? AppDelegate)?.stopMonitoring()
                                }
                            }

                        Toggle("Capture window titles", isOn: $windowTitleCapture)
                            .onChange(of: windowTitleCapture) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "windowTitleCapture")
                            }

                        Divider()

                        Toggle("Launch at login", isOn: $launchAtLogin.isEnabled)

                        if SMAppService.mainApp.status == .requiresApproval {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Requires approval in System Settings > Login Items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Button("Open Login Items Settings") {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .controlSize(.small)
                        }

                        if !AccessibilityHelper.hasAccessibilityPermission {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Accessibility permission required")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Spacer()
                                }

                                if !AccessibilityHelper.isRunningAsAppBundle {
                                    Text("Development build detected. You'll need to manually add the executable to Accessibility in System Settings.")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    HStack {
                                        Text(AccessibilityHelper.executablePath)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)

                                        Button(action: {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(AccessibilityHelper.executablePath, forType: .string)
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.caption2)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Copy path")
                                    }
                                }

                                HStack(spacing: 8) {
                                    Button("Open System Settings") {
                                        AccessibilityHelper.openAccessibilityPreferences()
                                    }
                                    .controlSize(.small)

                                    if AccessibilityHelper.isRunningAsAppBundle {
                                        Button("Request Access") {
                                            AccessibilityHelper.requestAccessibilityPermission()
                                        }
                                        .controlSize(.small)
                                    }
                                }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    }
                }

                // Excluded Apps Section
                SettingsSection(title: "Excluded Apps") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("These apps won't be tracked:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if excludedApps.isEmpty {
                            Text("No apps excluded")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(excludedApps) { app in
                                HStack {
                                    Text(app.appName)
                                        .font(.callout)
                                    Spacer()
                                    Button(action: {
                                        removeExcludedApp(app)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 2)
                            }
                        }

                        Divider()

                        Text("Add apps to exclude:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(runningApps.filter { app in
                                    !excludedApps.contains { $0.appBundleID == app.bundleID }
                                }) { app in
                                    Button(action: {
                                        addExcludedApp(app)
                                    }) {
                                        HStack(spacing: 4) {
                                            if let icon = app.icon {
                                                Image(nsImage: icon)
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                            }
                                            Text(app.name)
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color(NSColor.controlBackgroundColor))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // Data Section
                SettingsSection(title: "Data") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export your activity data:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Button("Export JSON") {
                                exportData()
                            }

                            Button("Export CSV") {
                                exportCSV()
                            }
                        }

                        Divider()

                        Button("Delete All Data") {
                            showDeleteConfirmation = true
                        }
                        .foregroundColor(.red)

                        Text("All data is stored locally on your Mac. Nothing is sent to any server except the Claude API for generating reports.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Updates Section
                SettingsSection(title: "Updates") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Current Version")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(UpdateManager.shared.fullVersionString)
                                    .font(.callout)
                                    .fontWeight(.medium)
                            }

                            Spacer()

                            if UpdateManager.shared.isSparkleAvailable {
                                Button(action: {
                                    UpdateManager.shared.checkForUpdates()
                                }) {
                                    if UpdateManager.shared.isCheckingForUpdates {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Label("Check for Updates", systemImage: "arrow.clockwise")
                                    }
                                }
                                .disabled(!UpdateManager.shared.canCheckForUpdates || UpdateManager.shared.isCheckingForUpdates)
                            }
                        }

                        if UpdateManager.shared.isSparkleAvailable {
                            HStack {
                                Text("Last checked:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(UpdateManager.shared.lastCheckFormatted)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            Toggle("Automatically check for updates", isOn: Binding(
                                get: { UpdateManager.shared.automaticallyChecksForUpdates },
                                set: { UpdateManager.shared.automaticallyChecksForUpdates = $0 }
                            ))

                            Toggle("Automatically download updates", isOn: Binding(
                                get: { UpdateManager.shared.automaticallyDownloadsUpdates },
                                set: { UpdateManager.shared.automaticallyDownloadsUpdates = $0 }
                            ))

                            HStack {
                                Text("Check frequency:")
                                    .font(.caption)

                                Picker("", selection: Binding(
                                    get: {
                                        UpdateCheckInterval.allCases.first {
                                            $0.seconds == UpdateManager.shared.updateCheckInterval
                                        } ?? .daily
                                    },
                                    set: { UpdateManager.shared.updateCheckInterval = $0.seconds }
                                )) {
                                    ForEach(UpdateCheckInterval.allCases, id: \.self) { interval in
                                        Text(interval.title).tag(interval)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 120)
                            }
                        } else {
                            Text("Updates available in release builds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // About Section
                SettingsSection(title: "About") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Roast")
                            .font(.callout)
                            .fontWeight(.medium)

                        Text("Version \(UpdateManager.shared.fullVersionString)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("A brutally honest productivity mirror.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 16)
            }
            .padding()
        }
        .onAppear {
            loadSettings()
        }
        .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all your tracking data and reports. This action cannot be undone.")
        }
    }

    private func loadSettings() {
        // Load API key (masked)
        if let key = KeychainHelper.getAPIKey() {
            apiKey = key
        }

        // Load preferences
        trackingEnabled = UserDefaults.standard.bool(forKey: "trackingEnabled")
        windowTitleCapture = UserDefaults.standard.bool(forKey: "windowTitleCapture")

        // Load default personality
        if let savedPersonality = UserDefaults.standard.string(forKey: "defaultPersonality"),
           let personality = ReportPersonality(rawValue: savedPersonality) {
            defaultPersonality = personality
        }

        // Load excluded apps
        do {
            excludedApps = try DatabaseManager.shared.getExcludedApps()
        } catch {
            print("Failed to load excluded apps: \(error)")
        }

        // Load running apps
        runningApps = AccessibilityHelper.getRunningApplications()
    }

    private func saveAPIKey() {
        if KeychainHelper.saveAPIKey(apiKey) {
            appState.apiKeyConfigured = true
        }
    }

    private func addExcludedApp(_ app: RunningAppInfo) {
        let excluded = ExcludedApp(appBundleID: app.bundleID, appName: app.name)
        do {
            try DatabaseManager.shared.addExcludedApp(excluded)
            excludedApps.append(excluded)
        } catch {
            print("Failed to add excluded app: \(error)")
        }
    }

    private func removeExcludedApp(_ app: ExcludedApp) {
        do {
            try DatabaseManager.shared.removeExcludedApp(bundleID: app.appBundleID)
            excludedApps.removeAll { $0.appBundleID == app.appBundleID }
        } catch {
            print("Failed to remove excluded app: \(error)")
        }
    }

    private func exportData() {
        do {
            let data = try DatabaseManager.shared.exportData()
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)

            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "roast_export_\(DateHelpers.formatExportDate()).json"

            if savePanel.runModal() == .OK, let url = savePanel.url {
                try jsonData.write(to: url)
            }
        } catch {
            print("Failed to export data: \(error)")
        }
    }

    private func exportCSV() {
        do {
            let data = try DatabaseManager.shared.exportData()

            // Build CSV content for sessions
            var csvContent = "Activity Sessions Export\n"
            csvContent += "App Name,Bundle ID,Window Title,Start Time,End Time,Duration (seconds),Is Active\n"

            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            for session in data.sessions {
                let startTime = dateFormatter.string(from: session.startTime)
                let endTime = session.endTime.map { dateFormatter.string(from: $0) } ?? ""
                let duration = String(format: "%.1f", session.duration)
                let windowTitle = session.windowTitle?.replacingOccurrences(of: ",", with: ";") ?? ""
                let appName = session.appName.replacingOccurrences(of: ",", with: ";")

                csvContent += "\(appName),\(session.appBundleID),\(windowTitle),\(startTime),\(endTime),\(duration),\(session.isActiveWindow)\n"
            }

            csvContent += "\n\nApp Visits Export\n"
            csvContent += "App Name,Bundle ID,Timestamp,Duration (seconds),Previous App Bundle ID\n"

            for visit in data.visits {
                let timestamp = dateFormatter.string(from: visit.timestamp)
                let appName = visit.appName.replacingOccurrences(of: ",", with: ";")
                let previousApp = visit.previousAppBundleID ?? ""

                csvContent += "\(appName),\(visit.appBundleID),\(timestamp),\(visit.durationSeconds),\(previousApp)\n"
            }

            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.commaSeparatedText]
            savePanel.nameFieldStringValue = "roast_export_\(DateHelpers.formatExportDate()).csv"

            if savePanel.runModal() == .OK, let url = savePanel.url {
                try csvContent.write(to: url, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Failed to export CSV: \(error)")
        }
    }

    private func deleteAllData() {
        do {
            try DatabaseManager.shared.deleteAllData()
            excludedApps = []
            appState.currentWeeklyReport = nil
            appState.todayStats = nil
        } catch {
            print("Failed to delete data: \(error)")
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            content
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
        }
    }
}

// MARK: - Personality Option

struct PersonalityOption: View {
    let personality: ReportPersonality
    let isSelected: Bool
    let onSelect: () -> Void

    var color: Color {
        switch personality {
        case .encouraging: return .green
        case .professional: return .blue
        case .neutral: return .gray
        case .roast: return .orange
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: personality.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(personality.rawValue)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(personality.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color : Color(NSColor.controlBackgroundColor))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Helper Extension

extension DateHelpers {
    static func formatExportDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState.shared)
        .frame(width: 400, height: 500)
}
