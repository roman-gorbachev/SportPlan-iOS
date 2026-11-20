import Foundation
import GRDB

nonisolated struct BackupSet: AppRecord, Sendable {
    static let databaseTableName = "set_entry"

    var id: UUID
    var workoutExerciseId: UUID
    var position: Int
    var weightG: Int
    var reps: Int?
    var durationSec: Int?
    var isWarmup: Bool
    var startedAt: Date?
    var completedAt: Date?
}
