import Foundation

struct WeeklyStats: Codable {
    let weekStart: Date
    let weekEnd: Date

    // Per-app metrics
    let appUsage: [AppUsageStats]

    // Behavioral patterns
    let totalContextSwitches: Int
    let averageSessionLength: TimeInterval
    let compulsiveChecks: [CompulsiveCheckPattern]
    let deepWorkSessions: [DeepWorkSession]
    let fragmentedHours: [FragmentedHour]

    // Daily patterns
    let dailyBreakdowns: [DailyBreakdown]
    let peakProductivityHours: [Int]
    let peakDistractionHours: [Int]

    // Comparisons (if previous week exists)
    let weekOverWeekChanges: WeekComparison?

    var totalTrackedTime: TimeInterval {
        appUsage.reduce(0) { $0 + $1.totalTime }
    }

    var uniqueApps: Int {
        appUsage.count
    }

    var totalDeepWorkMinutes: Int {
        Int(deepWorkSessions.reduce(0) { $0 + $1.duration } / 60)
    }
}

struct AppUsageStats: Codable, Identifiable {
    var id: String { bundleID }
    let appName: String
    let bundleID: String
    let totalTime: TimeInterval
    let totalSessions: Int
    let averageSessionLength: TimeInterval
    let briefVisits: Int // Under 30 seconds
    let extendedSessions: Int // Over 10 minutes
    let visitFrequency: Double // Times per hour when computer active

    var formattedTotalTime: String {
        TimeFormatters.formatDuration(totalTime)
    }

    var formattedAvgSession: String {
        TimeFormatters.formatDuration(averageSessionLength)
    }
}

struct CompulsiveCheckPattern: Codable, Identifiable {
    var id: String { appName }
    let appName: String
    let bundleID: String
    let checksPerDay: Double
    let averageDuration: TimeInterval
    let triggerApps: [String] // Apps you often check this AFTER

    var formattedChecksPerDay: String {
        String(format: "%.1f", checksPerDay)
    }

    var formattedAvgDuration: String {
        TimeFormatters.formatDuration(averageDuration)
    }
}

struct DeepWorkSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let startTime: Date
    let duration: TimeInterval
    let primaryApp: String
    let interruptions: Int

    init(
        id: UUID = UUID(),
        date: Date,
        startTime: Date,
        duration: TimeInterval,
        primaryApp: String,
        interruptions: Int
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.duration = duration
        self.primaryApp = primaryApp
        self.interruptions = interruptions
    }

    var formattedDuration: String {
        TimeFormatters.formatDuration(duration)
    }
}

struct FragmentedHour: Codable, Identifiable {
    var id: String { "\(date)-\(hour)" }
    let date: Date
    let hour: Int
    let switchCount: Int
    let appsUsed: [String]
}

struct DailyBreakdown: Codable, Identifiable {
    var id: Date { date }
    let date: Date
    let totalActiveTime: TimeInterval
    let contextSwitches: Int
    let topApps: [String]
    let deepWorkMinutes: Int
    let fragmentedHours: Int

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

struct WeekComparison: Codable {
    let contextSwitchChange: Double // Percentage change
    let deepWorkSessionsChange: Int // Absolute change
    let averageSessionLengthChange: Double // Percentage change
    let totalTimeChange: Double // Percentage change

    var contextSwitchChangeFormatted: String {
        formatPercentageChange(contextSwitchChange)
    }

    var sessionLengthChangeFormatted: String {
        formatPercentageChange(averageSessionLengthChange)
    }

    var totalTimeChangeFormatted: String {
        formatPercentageChange(totalTimeChange)
    }

    private func formatPercentageChange(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(Int(value))%"
    }
}
