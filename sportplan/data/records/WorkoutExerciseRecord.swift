import Domain
import Foundation
import GRDB

nonisolated struct WorkoutExerciseRecord: AppRecord {
    static let databaseTableName = "workout_exercise"

    var id: UUID
    var workoutId: UUID
    var exerciseId: UUID
    var position: Int
    var targetSets: Int?
    var targetRepsMin: Int?
    var targetRepsMax: Int?
    var restSec: Int

    init(_ workoutExercise: WorkoutExercise) {
        id = workoutExercise.id
        workoutId = workoutExercise.workoutId
        exerciseId = workoutExercise.exerciseId
        position = workoutExercise.position
        targetSets = workoutExercise.targetSets
        targetRepsMin = workoutExercise.targetReps?.min
        targetRepsMax = workoutExercise.targetReps?.max
        restSec = workoutExercise.restSeconds
    }

    func toDomainModel() throws -> WorkoutExercise {
        return WorkoutExercise(
            id: id,
            workoutId: workoutId,
            exerciseId: exerciseId,
            position: position,
            targetSets: targetSets,
            targetReps: try RepRange.fromColumns(min: targetRepsMin, max: targetRepsMax, table: Self.databaseTableName),
            restSeconds: restSec
        )
    }
}
