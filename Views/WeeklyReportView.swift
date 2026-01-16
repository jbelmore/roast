import SwiftUI
import AppKit

struct WeeklyReportView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPersonality: ReportPersonality = .roast
    @State private var isRegenerating = false
    @State private var showShareSheet = false
    @State private var shareableRoast: ShareableRoast?
    @State private var showCopiedToast = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with personality selector and generate button
                ReportHeaderSection(
                    report: appState.currentWeeklyReport,
                    selectedPersonality: $selectedPersonality,
                    isGenerating: appState.isGeneratingReport || isRegenerating,
                    onGenerate: generateReport,
                    isConfigured: ClaudeClient.shared.isConfigured
                )

                if !ClaudeClient.shared.isConfigured {
                    APIKeyWarning()
                } else if let report = appState.currentWeeklyReport {
                    // Stats summary
                    if let stats = report.weekStats {
                        WeeklyStatsSummary(stats: stats)
                    }

                    Divider()

                    // Personality badge
                    PersonalityBadge(personality: report.personality)

                    // AI Analysis
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Analysis")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            Spacer()

                            // Regenerate with different personality
                            Menu {
                                ForEach(ReportPersonality.allCases, id: \.self) { personality in
                                    Button {
                                        regenerateWithPersonality(personality)
                                    } label: {
                                        Label(personality.rawValue, systemImage: personality.icon)
                                    }
                                }
                            } label: {
                                Label("Change Style", systemImage: "sparkles")
                                    .font(.caption)
                            }
                            .menuStyle(.borderlessButton)
                            .disabled(isRegenerating)
                        }

                        MarkdownView(text: report.aiAnalysis)

                        // Share button for roasts
                        if report.isShareable {
                            ShareRoastSection(
                                report: report,
                                showCopiedToast: $showCopiedToast
                            )
                        }
                    }
                } else if !appState.isGeneratingReport {
                    // Empty state with personality picker
                    EmptyReportState(
                        selectedPersonality: $selectedPersonality,
                        onGenerate: generateReport,
                        isConfigured: ClaudeClient.shared.isConfigured
                    )
                }

                Spacer(minLength: 16)
            }
            .padding()
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                CopiedToast()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showCopiedToast)
        .onAppear {
            loadCurrentWeekReport()
            loadDefaultPersonality()
        }
    }

    private func loadDefaultPersonality() {
        if let savedPersonality = UserDefaults.standard.string(forKey: "defaultPersonality"),
           let personality = ReportPersonality(rawValue: savedPersonality) {
            selectedPersonality = personality
        }
    }

    private func generateReport() {
        Task {
            await appState.generateWeeklyReport(personality: selectedPersonality)
        }
    }

    private func regenerateWithPersonality(_ personality: ReportPersonality) {
        guard let report = appState.currentWeeklyReport else { return }

        isRegenerating = true

        Task {
            do {
                let newReport = try await ReportGenerator.shared.regenerateReport(report, personality: personality)
                await MainActor.run {
                    appState.currentWeeklyReport = newReport
                    isRegenerating = false
                }
            } catch {
                await MainActor.run {
                    isRegenerating = false
                }
            }
        }
    }

    private func loadCurrentWeekReport() {
        Task {
            do {
                if let report = try DatabaseManager.shared.getWeeklyReport(forWeekStarting: DateHelpers.startOfWeek()) {
                    await MainActor.run {
                        appState.currentWeeklyReport = report
                    }
                }
            } catch {
                print("Failed to load report: \(error)")
            }
        }
    }
}

// MARK: - Report Header Section

struct ReportHeaderSection: View {
    let report: WeeklyReport?
    @Binding var selectedPersonality: ReportPersonality
    let isGenerating: Bool
    let onGenerate: () -> Void
    let isConfigured: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Report")
                    .font(.headline)

                if let report = report {
                    Text(TimeFormatters.formatDateRange(
                        start: report.weekStartDate,
                        end: report.weekEndDate
                    ))
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isGenerating {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                HStack(spacing: 8) {
                    // Personality picker
                    Menu {
                        ForEach(ReportPersonality.allCases, id: \.self) { personality in
                            Button {
                                selectedPersonality = personality
                            } label: {
                                Label {
                                    VStack(alignment: .leading) {
                                        Text(personality.rawValue)
                                        Text(personality.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: personality.icon)
                                }
                            }
                        }
                    } label: {
                        Label(selectedPersonality.rawValue, systemImage: selectedPersonality.icon)
                            .font(.callout)
                    }
                    .menuStyle(.borderlessButton)

                    Button(action: onGenerate) {
                        Label(
                            report == nil ? "Generate" : "Refresh",
                            systemImage: report == nil ? "sparkles" : "arrow.clockwise"
                        )
                        .font(.callout)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!isConfigured)
                }
            }
        }
    }
}

// MARK: - Personality Badge

struct PersonalityBadge: View {
    let personality: ReportPersonality

    var color: Color {
        switch personality {
        case .encouraging: return .green
        case .professional: return .blue
        case .neutral: return .gray
        case .roast: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: personality.icon)
                .font(.caption)
            Text(personality.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Share Roast Section

struct ShareRoastSection: View {
    let report: WeeklyReport
    @Binding var showCopiedToast: Bool

    var body: some View {
        VStack(spacing: 12) {
            Divider()

            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Share Your Roast")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }

            HStack(spacing: 12) {
                // Copy full roast
                Button {
                    copyToClipboard(full: true)
                } label: {
                    Label("Copy Full Roast", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                // Copy short version
                Button {
                    copyToClipboard(full: false)
                } label: {
                    Label("Copy for Twitter", systemImage: "square.and.arrow.up")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }

            Text("Share your productivity roast with friends!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
        )
    }

    private func copyToClipboard(full: Bool) {
        if let shareable = ReportGenerator.shared.generateShareableRoast(from: report) {
            let text = full ? shareable.clipboardText : shareable.tweetText
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)

            showCopiedToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCopiedToast = false
            }
        }
    }
}

// MARK: - Copied Toast

struct CopiedToast: View {
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Copied to clipboard!")
                .font(.callout)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 4)
        )
        .padding(.bottom, 20)
    }
}

// MARK: - Empty Report State

struct EmptyReportState: View {
    @Binding var selectedPersonality: ReportPersonality
    let onGenerate: () -> Void
    let isConfigured: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No report yet")
                .font(.headline)

            Text("Choose a personality and generate your first weekly report!")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Personality selector grid
            VStack(spacing: 12) {
                Text("Choose your feedback style:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(ReportPersonality.allCases, id: \.self) { personality in
                        PersonalityCard(
                            personality: personality,
                            isSelected: selectedPersonality == personality,
                            onSelect: { selectedPersonality = personality }
                        )
                    }
                }
            }
            .padding()

            Button(action: onGenerate) {
                Label("Generate Report", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isConfigured)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Personality Card

struct PersonalityCard: View {
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
            VStack(spacing: 8) {
                Image(systemName: personality.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)

                Text(personality.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(personality.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? color : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weekly Stats Summary

struct WeeklyStatsSummary: View {
    let stats: WeeklyStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Week at a Glance")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MiniStatCard(
                    label: "Tracked",
                    value: TimeFormatters.formatDuration(stats.totalTrackedTime)
                )

                MiniStatCard(
                    label: "Switches",
                    value: "\(stats.totalContextSwitches)"
                )

                MiniStatCard(
                    label: "Deep Work",
                    value: "\(stats.totalDeepWorkMinutes)m"
                )
            }

            // Top apps mini chart
            if !stats.appUsage.isEmpty {
                MiniBarChart(apps: Array(stats.appUsage.prefix(5)))
            }
        }
    }
}

struct MiniStatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.callout)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - API Key Warning

struct APIKeyWarning: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.fill")
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("API Key Required")
                    .font(.callout)
                    .fontWeight(.medium)

                Text("Add your Claude API key in Settings to generate reports.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Simple Markdown View

struct MarkdownView: View {
    let text: String

    var body: some View {
        Text(parseMarkdown(text))
            .font(.callout)
            .textSelection(.enabled)
    }

    private func parseMarkdown(_ text: String) -> AttributedString {
        do {
            let attributedString = try AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            ))
            return attributedString
        } catch {
            return AttributedString(text)
        }
    }
}

#Preview {
    WeeklyReportView()
        .environmentObject(AppState.shared)
        .frame(width: 400, height: 500)
}
