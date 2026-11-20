import Foundation
import GRDB

nonisolated struct BackupPlannedExercise: AppRecord, Sendable {
    static let databaseTableName = "planned_exercise"

    var id: UUID
    var programDayId: UUID
    var exerciseId: UUID
    var position: Int
    var targetSets: Int
    var targetRepsMin: Int?
    var targetRepsMax: Int?
    var restSec: Int
    var startWeightG: Int?
    var targetDurationSec: Int?
}
