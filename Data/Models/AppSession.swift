import Foundation
import GRDB

struct AppSession: Identifiable, Codable, Equatable {
    var id: UUID
    var appBundleID: String
    var appName: String
    var windowTitle: String?
    var startTime: Date
    var endTime: Date?
    var isActiveWindow: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        appBundleID: String,
        appName: String,
        windowTitle: String? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        isActiveWindow: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.appBundleID = appBundleID
        self.appName = appName
        self.windowTitle = windowTitle
        self.startTime = startTime
        self.endTime = endTime
        self.isActiveWindow = isActiveWindow
        self.createdAt = createdAt
    }

    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var isBriefVisit: Bool {
        duration < 30
    }

    var isExtendedSession: Bool {
        duration > 600 // 10 minutes
    }
}

// MARK: - GRDB Record
extension AppSession: FetchableRecord, PersistableRecord {
    static let databaseTableName = "app_sessions"

    enum Columns: String, ColumnExpression {
        case id
        case appBundleID = "app_bundle_id"
        case appName = "app_name"
        case windowTitle = "window_title"
        case startTime = "start_time"
        case endTime = "end_time"
        case isActiveWindow = "is_active"
        case createdAt = "created_at"
    }

    init(row: Row) {
        id = row[Columns.id]
        appBundleID = row[Columns.appBundleID]
        appName = row[Columns.appName]
        windowTitle = row[Columns.windowTitle]
        startTime = row[Columns.startTime]
        endTime = row[Columns.endTime]
        isActiveWindow = row[Columns.isActiveWindow]
        createdAt = row[Columns.createdAt]
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.appBundleID] = appBundleID
        container[Columns.appName] = appName
        container[Columns.windowTitle] = windowTitle
        container[Columns.startTime] = startTime
        container[Columns.endTime] = endTime
        container[Columns.isActiveWindow] = isActiveWindow
        container[Columns.createdAt] = createdAt
    }
}
