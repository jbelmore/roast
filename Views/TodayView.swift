import SwiftUI

struct TodayView: View {
    @EnvironmentObject var appState: AppState
    @State private var dailySummary: String?
    @State private var isLoadingSummary = false
    @State private var summaryError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Current session card
                if let currentApp = appState.todayStats?.currentSessionApp,
                   let duration = appState.todayStats?.currentSessionDuration {
                    CurrentSessionCard(appName: currentApp, duration: duration)
                }

                // Quick stats
                if let stats = appState.todayStats {
                    QuickStatsGrid(stats: stats)
                }

                // Top apps
                if let stats = appState.todayStats, !stats.topApps.isEmpty {
                    TopAppsSection(apps: stats.topApps)
                }

                // Daily pulse
                DailyPulseSection(
                    summary: dailySummary,
                    isLoading: isLoadingSummary,
                    error: summaryError,
                    onRefresh: loadDailySummary
                )

                Spacer(minLength: 16)
            }
            .padding()
        }
        .onAppear {
            Task {
                await appState.refreshTodayStats()
            }
        }
    }

    private func loadDailySummary() {
        guard ClaudeClient.shared.isConfigured else {
            summaryError = "API key not configured"
            return
        }

        isLoadingSummary = true
        summaryError = nil

        Task {
            do {
                let summary = try await ReportGenerator.shared.generateDailySummary()
                await MainActor.run {
                    dailySummary = summary
                    isLoadingSummary = false
                }
            } catch {
                await MainActor.run {
                    summaryError = error.localizedDescription
                    isLoadingSummary = false
                }
            }
        }
    }
}

// MARK: - Current Session Card

struct CurrentSessionCard: View {
    let appName: String
    let duration: TimeInterval

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Session")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(appName)
                    .font(.headline)
            }

            Spacer()

            Text(TimeFormatters.formatDuration(duration))
                .font(.title2)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(0.1))
        )
    }
}

// MARK: - Quick Stats Grid

struct QuickStatsGrid: View {
    let stats: TodayStats

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                icon: "clock",
                label: "Active Time",
                value: TimeFormatters.formatDuration(stats.totalActiveTime)
            )

            StatCard(
                icon: "arrow.triangle.swap",
                label: "Context Switches",
                value: "\(stats.contextSwitches)"
            )

            StatCard(
                icon: "bolt.circle",
                label: "Quick Checks",
                value: "\(stats.compulsiveChecks)"
            )

            StatCard(
                icon: "brain",
                label: "Deep Work",
                value: "\(stats.deepWorkMinutes)m"
            )
        }
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Top Apps Section

struct TopAppsSection: View {
    let apps: [AppUsageStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Apps Today")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            ForEach(apps.prefix(5)) { app in
                AppUsageRow(app: app)
            }
        }
    }
}

// MARK: - Daily Pulse Section

struct DailyPulseSection: View {
    let summary: String?
    let isLoading: Bool
    let error: String?
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Daily Pulse")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }

            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating summary...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            } else if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
            } else if let summary = summary {
                Text(summary)
                    .font(.callout)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
            } else {
                Button(action: onRefresh) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Get AI Summary")
                    }
                    .font(.callout)
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
            }
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(AppState.shared)
        .frame(width: 400, height: 500)
}
