import Foundation
import GRDB

nonisolated struct BackupWorkoutExercise: AppRecord, Sendable {
    static let databaseTableName = "workout_exercise"

    var id: UUID
    var workoutId: UUID
    var exerciseId: UUID
    var position: Int
    var targetSets: Int?
    var targetRepsMin: Int?
    var targetRepsMax: Int?
    var restSec: Int
    var targetDurationSec: Int?
}
