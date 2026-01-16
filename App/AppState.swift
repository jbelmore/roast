import SwiftUI
import Combine

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isMonitoring: Bool = false
    @Published var currentView: NavigationTab = .today
    @Published var todayStats: TodayStats?
    @Published var currentWeeklyReport: WeeklyReport?
    @Published var isGeneratingReport: Bool = false
    @Published var apiKeyConfigured: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Check if API key is configured
        apiKeyConfigured = KeychainHelper.getAPIKey() != nil

        // Load today's stats periodically
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshTodayStats()
                }
            }
            .store(in: &cancellables)

        // Initial load
        Task {
            await refreshTodayStats()
        }
    }

    @MainActor
    func refreshTodayStats() async {
        do {
            let stats = try await AnalyticsEngine.shared.calculateTodayStats()
            self.todayStats = stats
        } catch {
            print("Failed to refresh today stats: \(error)")
        }
    }

    @MainActor
    func generateWeeklyReport(personality: ReportPersonality = .neutral) async {
        isGeneratingReport = true
        defer { isGeneratingReport = false }

        do {
            let report = try await ReportGenerator.shared.generateWeeklyReport(personality: personality)
            self.currentWeeklyReport = report
        } catch {
            print("Failed to generate weekly report: \(error)")
        }
    }
}

enum NavigationTab: String, CaseIterable {
    case today = "Today"
    case weeklyReport = "Weekly Report"
    case history = "History"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .today: return "clock"
        case .weeklyReport: return "doc.text"
        case .history: return "calendar"
        case .settings: return "gear"
        }
    }
}

struct TodayStats {
    let totalActiveTime: TimeInterval
    let contextSwitches: Int
    let topApps: [AppUsageStat]
    let compulsiveChecks: Int
    let deepWorkMinutes: Int
    let currentSessionApp: String?
    let currentSessionDuration: TimeInterval?
}

struct AppUsageStat: Identifiable {
    let id = UUID()
    let appName: String
    let bundleID: String
    let totalTime: TimeInterval
    let sessions: Int
    let briefVisits: Int
}
