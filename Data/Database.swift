import Foundation
import GRDB

class DatabaseManager {
    static let shared = DatabaseManager()

    private var dbQueue: DatabaseQueue?

    private init() {}

    func initialize() throws {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDirectoryURL = appSupportURL.appendingPathComponent("Roast", isDirectory: true)

        try fileManager.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true)

        // Migrate from old location if exists
        let oldDirectoryURL = appSupportURL.appendingPathComponent("HonestyMirror", isDirectory: true)
        let oldDatabaseURL = oldDirectoryURL.appendingPathComponent("honesty_mirror.sqlite")
        let databaseURL = appDirectoryURL.appendingPathComponent("roast.sqlite")

        if fileManager.fileExists(atPath: oldDatabaseURL.path) && !fileManager.fileExists(atPath: databaseURL.path) {
            try? fileManager.moveItem(at: oldDatabaseURL, to: databaseURL)
            try? fileManager.removeItem(at: oldDirectoryURL)
        }

        var config = Configuration()
        config.foreignKeysEnabled = true
        config.readonly = false

        dbQueue = try DatabaseQueue(path: databaseURL.path, configuration: config)

        try migrator.migrate(dbQueue!)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial") { db in
            // App sessions table
            try db.create(table: "app_sessions") { t in
                t.column("id", .text).primaryKey()
                t.column("app_bundle_id", .text).notNull()
                t.column("app_name", .text).notNull()
                t.column("window_title", .text)
                t.column("start_time", .double).notNull()
                t.column("end_time", .double)
                t.column("is_active", .integer).notNull().defaults(to: 1)
                t.column("created_at", .double).notNull()
            }

            // App visits table
            try db.create(table: "app_visits") { t in
                t.column("id", .text).primaryKey()
                t.column("app_bundle_id", .text).notNull()
                t.column("app_name", .text).notNull()
                t.column("timestamp", .double).notNull()
                t.column("duration_seconds", .double).notNull()
                t.column("previous_app_bundle_id", .text)
                t.column("created_at", .double).notNull()
            }

            // Weekly reports table
            try db.create(table: "weekly_reports") { t in
                t.column("id", .text).primaryKey()
                t.column("week_start_date", .double).notNull()
                t.column("week_end_date", .double).notNull()
                t.column("raw_stats_json", .text).notNull()
                t.column("ai_analysis", .text).notNull()
                t.column("created_at", .double).notNull()
            }

            // Excluded apps table
            try db.create(table: "excluded_apps") { t in
                t.column("app_bundle_id", .text).primaryKey()
                t.column("app_name", .text).notNull()
                t.column("excluded_at", .double).notNull()
            }

            // Indexes
            try db.create(index: "idx_sessions_time", on: "app_sessions", columns: ["start_time"])
            try db.create(index: "idx_visits_time", on: "app_visits", columns: ["timestamp"])
            try db.create(index: "idx_reports_week", on: "weekly_reports", columns: ["week_start_date"])
        }

        // Add personality column to weekly_reports
        migrator.registerMigration("v2_add_personality") { db in
            try db.alter(table: "weekly_reports") { t in
                t.add(column: "personality", .text).defaults(to: "Neutral")
            }
        }

        return migrator
    }

    // MARK: - Database Operations

    func read<T>(_ block: (Database) throws -> T) throws -> T {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        return try dbQueue.read(block)
    }

    func write<T>(_ block: (Database) throws -> T) throws -> T {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        return try dbQueue.write(block)
    }

    // MARK: - Convenience Methods

    func saveSession(_ session: AppSession) throws {
        try write { db in
            try session.save(db)
        }
    }

    func saveVisit(_ visit: AppVisit) throws {
        try write { db in
            try visit.save(db)
        }
    }

    func getSessionsForDateRange(start: Date, end: Date) throws -> [AppSession] {
        try read { db in
            try AppSession
                .filter(AppSession.Columns.startTime >= start.timeIntervalSinceReferenceDate)
                .filter(AppSession.Columns.startTime <= end.timeIntervalSinceReferenceDate)
                .order(AppSession.Columns.startTime)
                .fetchAll(db)
        }
    }

    func getVisitsForDateRange(start: Date, end: Date) throws -> [AppVisit] {
        try read { db in
            try AppVisit
                .filter(AppVisit.Columns.timestamp >= start.timeIntervalSinceReferenceDate)
                .filter(AppVisit.Columns.timestamp <= end.timeIntervalSinceReferenceDate)
                .order(AppVisit.Columns.timestamp)
                .fetchAll(db)
        }
    }

    func getExcludedApps() throws -> [ExcludedApp] {
        try read { db in
            try ExcludedApp.fetchAll(db)
        }
    }

    func addExcludedApp(_ app: ExcludedApp) throws {
        try write { db in
            try app.save(db)
        }
    }

    func removeExcludedApp(bundleID: String) throws {
        _ = try write { db in
            try ExcludedApp.deleteOne(db, key: bundleID)
        }
    }

    func isAppExcluded(bundleID: String) throws -> Bool {
        try read { db in
            try ExcludedApp.fetchOne(db, key: bundleID) != nil
        }
    }

    func saveWeeklyReport(_ report: WeeklyReport) throws {
        try write { db in
            try report.save(db)
        }
    }

    func getWeeklyReports(limit: Int = 10) throws -> [WeeklyReport] {
        try read { db in
            try WeeklyReport
                .order(WeeklyReport.Columns.weekStartDate.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func getWeeklyReport(forWeekStarting date: Date) throws -> WeeklyReport? {
        let startOfWeek = DateHelpers.startOfWeek(date)
        return try read { db in
            try WeeklyReport
                .filter(WeeklyReport.Columns.weekStartDate == startOfWeek.timeIntervalSinceReferenceDate)
                .fetchOne(db)
        }
    }

    func deleteAllData() throws {
        try write { db in
            try AppSession.deleteAll(db)
            try AppVisit.deleteAll(db)
            try WeeklyReport.deleteAll(db)
        }
    }

    func exportData() throws -> ExportedData {
        try read { db in
            let sessions = try AppSession.fetchAll(db)
            let visits = try AppVisit.fetchAll(db)
            let reports = try WeeklyReport.fetchAll(db)
            let excludedApps = try ExcludedApp.fetchAll(db)

            return ExportedData(
                sessions: sessions,
                visits: visits,
                reports: reports,
                excludedApps: excludedApps,
                exportDate: Date()
            )
        }
    }
}

// MARK: - Custom Errors

enum DatabaseError: Error, LocalizedError {
    case notInitialized

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database has not been initialized"
        }
    }
}

// MARK: - Export Data Structure

struct ExportedData: Codable {
    let sessions: [AppSession]
    let visits: [AppVisit]
    let reports: [WeeklyReport]
    let excludedApps: [ExcludedApp]
    let exportDate: Date
}
