import Foundation

class ReportGenerator {
    static let shared = ReportGenerator()

    private init() {}

    // MARK: - Weekly Report Generation

    func generateWeeklyReport(
        weekStart: Date? = nil,
        personality: ReportPersonality = .neutral
    ) async throws -> WeeklyReport {
        // Calculate stats
        let stats = try await AnalyticsEngine.shared.calculateWeeklyStats(weekStart: weekStart)

        // Generate AI analysis with personality
        let analysis = try await generateAnalysis(stats: stats, personality: personality)

        // Encode stats to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let statsJSON = try encoder.encode(stats)
        let statsJSONString = String(data: statsJSON, encoding: .utf8) ?? "{}"

        // Create report
        let report = WeeklyReport(
            weekStartDate: stats.weekStart,
            weekEndDate: stats.weekEnd,
            rawStatsJSON: statsJSONString,
            aiAnalysis: analysis,
            personality: personality
        )

        // Save to database
        try DatabaseManager.shared.saveWeeklyReport(report)

        return report
    }

    private func generateAnalysis(stats: WeeklyStats, personality: ReportPersonality) async throws -> String {
        let systemPrompt = Prompts.systemPrompt(for: personality)
        let userPrompt = Prompts.buildWeeklyAnalysisPrompt(stats: stats, personality: personality)

        return try await ClaudeClient.shared.sendMessage(
            systemPrompt: systemPrompt,
            userMessage: userPrompt,
            maxTokens: personality == .roast ? 1800 : 1500  // Give roasts a bit more room
        )
    }

    // MARK: - Daily Summary

    func generateDailySummary(personality: ReportPersonality = .neutral) async throws -> String {
        let stats = try await AnalyticsEngine.shared.calculateTodayStats()
        let systemPrompt = Prompts.dailySummaryPrompt(for: personality)
        let userPrompt = Prompts.buildDailySummaryPrompt(stats: stats, personality: personality)

        return try await ClaudeClient.shared.sendMessage(
            systemPrompt: systemPrompt,
            userMessage: userPrompt,
            maxTokens: personality == .roast ? 400 : 300
        )
    }

    // MARK: - Report Regeneration

    func regenerateReport(
        _ report: WeeklyReport,
        personality: ReportPersonality
    ) async throws -> WeeklyReport {
        guard let stats = report.weekStats else {
            throw ReportError.invalidStats
        }

        let systemPrompt = Prompts.systemPrompt(for: personality)
        let userPrompt = Prompts.buildWeeklyAnalysisPrompt(stats: stats, personality: personality)

        let newAnalysis = try await ClaudeClient.shared.sendMessage(
            systemPrompt: systemPrompt,
            userMessage: userPrompt,
            maxTokens: personality == .roast ? 1800 : 1500
        )

        let updatedReport = WeeklyReport(
            id: report.id,
            weekStartDate: report.weekStartDate,
            weekEndDate: report.weekEndDate,
            rawStatsJSON: report.rawStatsJSON,
            aiAnalysis: newAnalysis,
            personality: personality,
            createdAt: report.createdAt
        )

        try DatabaseManager.shared.saveWeeklyReport(updatedReport)

        return updatedReport
    }

    // MARK: - Shareable Content Generation

    func generateShareableRoast(from report: WeeklyReport) -> ShareableRoast? {
        guard report.personality == .roast else { return nil }

        // Extract the shareable burn line (last line after the 🔥 emoji)
        let lines = report.aiAnalysis.components(separatedBy: "\n")
        var shareableLine: String?
        var foundFireEmoji = false

        for line in lines.reversed() {
            if line.contains("🔥") {
                foundFireEmoji = true
                // Get the next non-empty line after the fire emoji line
                if let burnLine = lines.last(where: { !$0.isEmpty && !$0.contains("🔥") }) {
                    shareableLine = burnLine
                }
                break
            }
        }

        // If we found the fire emoji section, extract the burn
        if foundFireEmoji, let lastLine = lines.last(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            if !lastLine.contains("🔥") {
                shareableLine = lastLine
            }
        }

        // Fallback: use the verdict/headline if available
        if shareableLine == nil {
            if let verdictStart = report.aiAnalysis.range(of: "**The Verdict**"),
               let verdictEnd = report.aiAnalysis.range(of: "\n\n", range: verdictStart.upperBound..<report.aiAnalysis.endIndex) {
                let verdictContent = String(report.aiAnalysis[verdictStart.upperBound..<verdictEnd.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "**", with: "")
                    .trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
                if !verdictContent.isEmpty {
                    shareableLine = verdictContent
                }
            }
        }

        let weekRange = TimeFormatters.formatDateRange(start: report.weekStartDate, end: report.weekEndDate)

        return ShareableRoast(
            fullRoast: report.aiAnalysis,
            shareableBurn: shareableLine ?? "I got absolutely destroyed by Roast 🔥",
            weekRange: weekRange,
            generatedAt: report.createdAt
        )
    }
}

// MARK: - Shareable Roast

struct ShareableRoast {
    let fullRoast: String
    let shareableBurn: String
    let weekRange: String
    let generatedAt: Date

    var tweetText: String {
        """
        \(shareableBurn)

        — My productivity roast for \(weekRange)
        🔥 Roasted by Roast
        """
    }

    var clipboardText: String {
        """
        \(fullRoast)

        ---
        Roasted by Roast • \(weekRange)
        """
    }

    var shortShareText: String {
        """
        🔥 \(shareableBurn)

        Get roasted: Roast
        """
    }
}

// MARK: - Errors

enum ReportError: Error, LocalizedError {
    case invalidStats
    case generationFailed
    case apiKeyNotConfigured

    var errorDescription: String? {
        switch self {
        case .invalidStats:
            return "Could not parse report statistics"
        case .generationFailed:
            return "Failed to generate report"
        case .apiKeyNotConfigured:
            return "Claude API key is not configured"
        }
    }
}
