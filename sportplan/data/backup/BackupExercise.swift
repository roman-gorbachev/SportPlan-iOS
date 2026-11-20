import Foundation
import GRDB

nonisolated struct BackupExercise: AppRecord, Sendable {
    static let databaseTableName = "exercise"

    var id: UUID
    var name: String
    var description: String?
    var equipmentId: UUID?
    var metric: String
    var restSec: Int
    var isArchived: Bool
    var createdAt: Date
}
