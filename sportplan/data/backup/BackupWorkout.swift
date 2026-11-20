import Foundation
import GRDB

nonisolated struct BackupWorkout: AppRecord, Sendable {
    static let databaseTableName = "workout"

    var id: UUID
    var programDayId: UUID?
    var programDayName: String?
    var programDayLabel: String?
    var startedAt: Date
    var finishedAt: Date?
    var note: String?
    var restStartedAt: Date?
    var restEndsAt: Date?
}
