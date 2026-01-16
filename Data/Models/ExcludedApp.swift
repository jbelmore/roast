import Foundation
import GRDB

struct ExcludedApp: Identifiable, Codable, Equatable {
    var id: String { appBundleID }
    var appBundleID: String
    var appName: String
    var excludedAt: Date

    init(
        appBundleID: String,
        appName: String,
        excludedAt: Date = Date()
    ) {
        self.appBundleID = appBundleID
        self.appName = appName
        self.excludedAt = excludedAt
    }
}

// MARK: - GRDB Record
extension ExcludedApp: FetchableRecord, PersistableRecord {
    static let databaseTableName = "excluded_apps"

    enum Columns: String, ColumnExpression {
        case appBundleID = "app_bundle_id"
        case appName = "app_name"
        case excludedAt = "excluded_at"
    }

    init(row: Row) {
        appBundleID = row[Columns.appBundleID]
        appName = row[Columns.appName]
        // Decode date from timeIntervalSinceReferenceDate (Double)
        excludedAt = Date(timeIntervalSinceReferenceDate: row[Columns.excludedAt])
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.appBundleID] = appBundleID
        container[Columns.appName] = appName
        // Encode date as timeIntervalSinceReferenceDate (Double)
        container[Columns.excludedAt] = excludedAt.timeIntervalSinceReferenceDate
    }
}
