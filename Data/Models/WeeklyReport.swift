import Foundation
import GRDB

struct WeeklyReport: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var weekStartDate: Date
    var weekEndDate: Date
    var rawStatsJSON: String
    var aiAnalysis: String
    var personality: ReportPersonality
    var createdAt: Date

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        weekEndDate: Date,
        rawStatsJSON: String,
        aiAnalysis: String,
        personality: ReportPersonality = .neutral,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.rawStatsJSON = rawStatsJSON
        self.aiAnalysis = aiAnalysis
        self.personality = personality
        self.createdAt = createdAt
    }

    var weekStats: WeeklyStats? {
        guard let data = rawStatsJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WeeklyStats.self, from: data)
    }

    var isRoast: Bool {
        personality == .roast
    }

    var isShareable: Bool {
        personality.isShareable
    }
}

// MARK: - GRDB Record
extension WeeklyReport: FetchableRecord, PersistableRecord {
    static let databaseTableName = "weekly_reports"

    enum Columns: String, ColumnExpression {
        case id
        case weekStartDate = "week_start_date"
        case weekEndDate = "week_end_date"
        case rawStatsJSON = "raw_stats_json"
        case aiAnalysis = "ai_analysis"
        case personality
        case createdAt = "created_at"
    }

    init(row: Row) {
        id = row[Columns.id]
        weekStartDate = row[Columns.weekStartDate]
        weekEndDate = row[Columns.weekEndDate]
        rawStatsJSON = row[Columns.rawStatsJSON]
        aiAnalysis = row[Columns.aiAnalysis]
        // Handle migration: default to neutral if personality is nil
        if let personalityRaw: String = row[Columns.personality],
           let p = ReportPersonality(rawValue: personalityRaw) {
            personality = p
        } else {
            personality = .neutral
        }
        createdAt = row[Columns.createdAt]
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.weekStartDate] = weekStartDate
        container[Columns.weekEndDate] = weekEndDate
        container[Columns.rawStatsJSON] = rawStatsJSON
        container[Columns.aiAnalysis] = aiAnalysis
        container[Columns.personality] = personality.rawValue
        container[Columns.createdAt] = createdAt
    }
}
