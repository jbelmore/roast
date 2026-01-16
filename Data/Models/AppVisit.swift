import Foundation
import GRDB

struct AppVisit: Identifiable, Codable, Equatable {
    var id: UUID
    var appBundleID: String
    var appName: String
    var timestamp: Date
    var durationSeconds: TimeInterval
    var previousAppBundleID: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        appBundleID: String,
        appName: String,
        timestamp: Date = Date(),
        durationSeconds: TimeInterval,
        previousAppBundleID: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.appBundleID = appBundleID
        self.appName = appName
        self.timestamp = timestamp
        self.durationSeconds = durationSeconds
        self.previousAppBundleID = previousAppBundleID
        self.createdAt = createdAt
    }

    var isBriefCheck: Bool {
        durationSeconds < 30
    }

    var isCompulsiveCheck: Bool {
        durationSeconds < 10
    }
}

// MARK: - GRDB Record
extension AppVisit: FetchableRecord, PersistableRecord {
    static let databaseTableName = "app_visits"

    enum Columns: String, ColumnExpression {
        case id
        case appBundleID = "app_bundle_id"
        case appName = "app_name"
        case timestamp
        case durationSeconds = "duration_seconds"
        case previousAppBundleID = "previous_app_bundle_id"
        case createdAt = "created_at"
    }

    init(row: Row) {
        id = row[Columns.id]
        appBundleID = row[Columns.appBundleID]
        appName = row[Columns.appName]
        timestamp = row[Columns.timestamp]
        durationSeconds = row[Columns.durationSeconds]
        previousAppBundleID = row[Columns.previousAppBundleID]
        createdAt = row[Columns.createdAt]
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.appBundleID] = appBundleID
        container[Columns.appName] = appName
        container[Columns.timestamp] = timestamp
        container[Columns.durationSeconds] = durationSeconds
        container[Columns.previousAppBundleID] = previousAppBundleID
        container[Columns.createdAt] = createdAt
    }
}
