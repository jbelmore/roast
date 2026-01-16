import Foundation

class AnalyticsEngine {
    static let shared = AnalyticsEngine()

    private init() {}

    // MARK: - Today Stats

    func calculateTodayStats() async throws -> TodayStats {
        let startOfDay = DateHelpers.startOfDay()
        let endOfDay = DateHelpers.endOfDay()

        let sessions = try DatabaseManager.shared.getSessionsForDateRange(start: startOfDay, end: endOfDay)
        let visits = try DatabaseManager.shared.getVisitsForDateRange(start: startOfDay, end: endOfDay)

        // Calculate total active time
        let totalActiveTime = sessions.reduce(0.0) { $0 + $1.duration }

        // Context switches = number of visits
        let contextSwitches = visits.count

        // Top apps by time
        let appTimes = Dictionary(grouping: sessions, by: { $0.appBundleID })
            .mapValues { sessions in
                (
                    name: sessions.first?.appName ?? "Unknown",
                    time: sessions.reduce(0.0) { $0 + $1.duration },
                    sessions: sessions.count,
                    briefVisits: sessions.filter { $0.isBriefVisit }.count
                )
            }

        let topApps = appTimes
            .sorted { $0.value.time > $1.value.time }
            .prefix(5)
            .map { bundleID, data in
                AppUsageStat(
                    appName: data.name,
                    bundleID: bundleID,
                    totalTime: data.time,
                    sessions: data.sessions,
                    briefVisits: data.briefVisits
                )
            }

        // Count compulsive checks (brief visits < 10 seconds)
        let compulsiveChecks = visits.filter { $0.isCompulsiveCheck }.count

        // Deep work minutes (sessions > 30 min in productive apps)
        let deepWorkMinutes = Int(sessions.filter { $0.duration > 1800 }.reduce(0.0) { $0 + $1.duration } / 60)

        // Current session info
        var currentSessionApp: String?
        var currentSessionDuration: TimeInterval?

        if let lastSession = sessions.last, lastSession.endTime == nil {
            currentSessionApp = lastSession.appName
            currentSessionDuration = lastSession.duration
        }

        return TodayStats(
            totalActiveTime: totalActiveTime,
            contextSwitches: contextSwitches,
            topApps: topApps,
            compulsiveChecks: compulsiveChecks,
            deepWorkMinutes: deepWorkMinutes,
            currentSessionApp: currentSessionApp,
            currentSessionDuration: currentSessionDuration
        )
    }

    // MARK: - Weekly Stats

    func calculateWeeklyStats(weekStart: Date? = nil) async throws -> WeeklyStats {
        let start = weekStart ?? DateHelpers.startOfWeek()
        let end = DateHelpers.endOfWeek(start)

        let sessions = try DatabaseManager.shared.getSessionsForDateRange(start: start, end: end)
        let visits = try DatabaseManager.shared.getVisitsForDateRange(start: start, end: end)

        // Per-app metrics
        let appUsage = calculateAppUsageStats(sessions: sessions, visits: visits, start: start, end: end)

        // Behavioral patterns
        let totalContextSwitches = visits.count
        let averageSessionLength = sessions.isEmpty ? 0 : sessions.reduce(0.0) { $0 + $1.duration } / Double(sessions.count)
        let compulsiveChecks = detectCompulsiveChecks(visits: visits, dayCount: 7)
        let deepWorkSessions = detectDeepWorkSessions(sessions: sessions)
        let fragmentedHours = detectFragmentedHours(visits: visits)

        // Daily patterns
        let dailyBreakdowns = calculateDailyBreakdowns(sessions: sessions, visits: visits, start: start, end: end)
        let (peakProductivityHours, peakDistractionHours) = calculatePeakHours(sessions: sessions, visits: visits)

        // Week over week comparison
        let weekOverWeekChanges = try calculateWeekComparison(currentWeekStart: start)

        return WeeklyStats(
            weekStart: start,
            weekEnd: end,
            appUsage: appUsage,
            totalContextSwitches: totalContextSwitches,
            averageSessionLength: averageSessionLength,
            compulsiveChecks: compulsiveChecks,
            deepWorkSessions: deepWorkSessions,
            fragmentedHours: fragmentedHours,
            dailyBreakdowns: dailyBreakdowns,
            peakProductivityHours: peakProductivityHours,
            peakDistractionHours: peakDistractionHours,
            weekOverWeekChanges: weekOverWeekChanges
        )
    }

    // MARK: - App Usage Stats

    private func calculateAppUsageStats(sessions: [AppSession], visits: [AppVisit], start: Date, end: Date) -> [AppUsageStats] {
        let groupedSessions = Dictionary(grouping: sessions, by: { $0.appBundleID })

        // Calculate total tracked hours
        let totalTrackedHours = max(1, sessions.reduce(0.0) { $0 + $1.duration } / 3600)

        return groupedSessions.map { bundleID, appSessions in
            let totalTime = appSessions.reduce(0.0) { $0 + $1.duration }
            let briefVisits = appSessions.filter { $0.isBriefVisit }.count
            let extendedSessions = appSessions.filter { $0.isExtendedSession }.count
            let avgSessionLength = appSessions.isEmpty ? 0 : totalTime / Double(appSessions.count)
            let visitFrequency = Double(appSessions.count) / totalTrackedHours

            return AppUsageStats(
                appName: appSessions.first?.appName ?? "Unknown",
                bundleID: bundleID,
                totalTime: totalTime,
                totalSessions: appSessions.count,
                averageSessionLength: avgSessionLength,
                briefVisits: briefVisits,
                extendedSessions: extendedSessions,
                visitFrequency: visitFrequency
            )
        }
        .sorted { $0.totalTime > $1.totalTime }
    }

    // MARK: - Compulsive Check Detection

    private func detectCompulsiveChecks(visits: [AppVisit], dayCount: Int) -> [CompulsiveCheckPattern] {
        let grouped = Dictionary(grouping: visits, by: { $0.appBundleID })

        return grouped.compactMap { bundleID, appVisits in
            let briefVisits = appVisits.filter { $0.isBriefCheck }
            let checksPerDay = Double(briefVisits.count) / Double(dayCount)

            // Threshold: more than 5 brief checks per day = compulsive
            guard checksPerDay > 5 else { return nil }

            let avgDuration = briefVisits.isEmpty ? 0 : briefVisits.reduce(0.0) { $0 + $1.durationSeconds } / Double(briefVisits.count)

            // Find trigger apps (apps frequently visited before this one)
            let triggerApps = findTriggerApps(for: bundleID, in: appVisits, allVisits: visits)

            return CompulsiveCheckPattern(
                appName: appVisits.first?.appName ?? "Unknown",
                bundleID: bundleID,
                checksPerDay: checksPerDay,
                averageDuration: avgDuration,
                triggerApps: triggerApps
            )
        }
        .sorted { $0.checksPerDay > $1.checksPerDay }
    }

    private func findTriggerApps(for bundleID: String, in appVisits: [AppVisit], allVisits: [AppVisit]) -> [String] {
        var triggerCounts: [String: Int] = [:]

        for visit in appVisits {
            if let previousApp = visit.previousAppBundleID, previousApp != bundleID {
                triggerCounts[previousApp, default: 0] += 1
            }
        }

        return triggerCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .compactMap { bundleID, _ in
                allVisits.first { $0.appBundleID == bundleID }?.appName
            }
    }

    // MARK: - Deep Work Detection

    private func detectDeepWorkSessions(sessions: [AppSession]) -> [DeepWorkSession] {
        // Find sessions longer than 30 minutes
        let deepSessions = sessions.filter { $0.duration >= 1800 }

        return deepSessions.map { session in
            DeepWorkSession(
                date: DateHelpers.startOfDay(session.startTime),
                startTime: session.startTime,
                duration: session.duration,
                primaryApp: session.appName,
                interruptions: 0 // Could be enhanced to detect interruptions
            )
        }
        .sorted { $0.duration > $1.duration }
    }

    // MARK: - Fragmented Hours Detection

    private func detectFragmentedHours(visits: [AppVisit]) -> [FragmentedHour] {
        // Group visits by hour
        let grouped = Dictionary(grouping: visits) { visit -> String in
            let day = DateHelpers.startOfDay(visit.timestamp)
            let hour = DateHelpers.hourOfDay(visit.timestamp)
            return "\(day.timeIntervalSinceReferenceDate)-\(hour)"
        }

        return grouped.compactMap { _, hourVisits in
            guard hourVisits.count >= 10 else { return nil }

            let firstVisit = hourVisits.first!
            let date = DateHelpers.startOfDay(firstVisit.timestamp)
            let hour = DateHelpers.hourOfDay(firstVisit.timestamp)
            let appsUsed = Array(Set(hourVisits.map { $0.appName }))

            return FragmentedHour(
                date: date,
                hour: hour,
                switchCount: hourVisits.count,
                appsUsed: appsUsed
            )
        }
        .sorted { $0.switchCount > $1.switchCount }
    }

    // MARK: - Daily Breakdowns

    private func calculateDailyBreakdowns(sessions: [AppSession], visits: [AppVisit], start: Date, end: Date) -> [DailyBreakdown] {
        let days = DateHelpers.daysInRange(start: start, end: end)

        return days.map { day in
            let dayEnd = DateHelpers.endOfDay(day)
            let daySessions = sessions.filter { $0.startTime >= day && $0.startTime <= dayEnd }
            let dayVisits = visits.filter { $0.timestamp >= day && $0.timestamp <= dayEnd }

            let totalTime = daySessions.reduce(0.0) { $0 + $1.duration }
            let switches = dayVisits.count

            let topApps = Dictionary(grouping: daySessions, by: { $0.appBundleID })
                .mapValues { $0.reduce(0.0) { $0 + $1.duration } }
                .sorted { $0.value > $1.value }
                .prefix(3)
                .compactMap { bundleID, _ in
                    daySessions.first { $0.appBundleID == bundleID }?.appName
                }

            let deepWorkMinutes = Int(daySessions.filter { $0.duration > 1800 }.reduce(0.0) { $0 + $1.duration } / 60)

            let fragmentedHoursCount = detectFragmentedHours(visits: dayVisits).count

            return DailyBreakdown(
                date: day,
                totalActiveTime: totalTime,
                contextSwitches: switches,
                topApps: topApps,
                deepWorkMinutes: deepWorkMinutes,
                fragmentedHours: fragmentedHoursCount
            )
        }
    }

    // MARK: - Peak Hours

    private func calculatePeakHours(sessions: [AppSession], visits: [AppVisit]) -> (productive: [Int], distracted: [Int]) {
        // Group sessions by hour and calculate productivity
        var hourlyDeepWork: [Int: TimeInterval] = [:]
        var hourlyFragmentation: [Int: Int] = [:]

        for session in sessions {
            let hour = DateHelpers.hourOfDay(session.startTime)
            if session.duration > 1800 {
                hourlyDeepWork[hour, default: 0] += session.duration
            }
        }

        for visit in visits {
            let hour = DateHelpers.hourOfDay(visit.timestamp)
            hourlyFragmentation[hour, default: 0] += 1
        }

        let productiveHours = hourlyDeepWork
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }

        let distractedHours = hourlyFragmentation
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }

        return (Array(productiveHours), Array(distractedHours))
    }

    // MARK: - Week Comparison

    private func calculateWeekComparison(currentWeekStart: Date) throws -> WeekComparison? {
        let previousWeekStart = DateHelpers.previousWeekStart(currentWeekStart)
        let previousWeekEnd = DateHelpers.previousWeekEnd(currentWeekStart)

        let previousSessions = try DatabaseManager.shared.getSessionsForDateRange(start: previousWeekStart, end: previousWeekEnd)
        let previousVisits = try DatabaseManager.shared.getVisitsForDateRange(start: previousWeekStart, end: previousWeekEnd)

        guard !previousSessions.isEmpty else { return nil }

        let currentSessions = try DatabaseManager.shared.getSessionsForDateRange(start: currentWeekStart, end: DateHelpers.endOfWeek(currentWeekStart))
        let currentVisits = try DatabaseManager.shared.getVisitsForDateRange(start: currentWeekStart, end: DateHelpers.endOfWeek(currentWeekStart))

        let currentSwitches = currentVisits.count
        let previousSwitches = previousVisits.count
        let switchChange = previousSwitches == 0 ? 0 : Double(currentSwitches - previousSwitches) / Double(previousSwitches) * 100

        let currentDeepWork = currentSessions.filter { $0.duration > 1800 }.count
        let previousDeepWork = previousSessions.filter { $0.duration > 1800 }.count
        let deepWorkChange = currentDeepWork - previousDeepWork

        let currentAvgSession = currentSessions.isEmpty ? 0 : currentSessions.reduce(0.0) { $0 + $1.duration } / Double(currentSessions.count)
        let previousAvgSession = previousSessions.isEmpty ? 0 : previousSessions.reduce(0.0) { $0 + $1.duration } / Double(previousSessions.count)
        let sessionChange = previousAvgSession == 0 ? 0 : (currentAvgSession - previousAvgSession) / previousAvgSession * 100

        let currentTotalTime = currentSessions.reduce(0.0) { $0 + $1.duration }
        let previousTotalTime = previousSessions.reduce(0.0) { $0 + $1.duration }
        let timeChange = previousTotalTime == 0 ? 0 : (currentTotalTime - previousTotalTime) / previousTotalTime * 100

        return WeekComparison(
            contextSwitchChange: switchChange,
            deepWorkSessionsChange: deepWorkChange,
            averageSessionLengthChange: sessionChange,
            totalTimeChange: timeChange
        )
    }
}
