import Domain
import Foundation
import GRDB

nonisolated struct PlannedExerciseRecord: AppRecord {
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

    init(_ planned: PlannedExercise) {
        id = planned.id
        programDayId = planned.programDayId
        exerciseId = planned.exerciseId
        position = planned.position
        targetSets = planned.targetSets
        targetRepsMin = planned.targetReps?.min
        targetRepsMax = planned.targetReps?.max
        restSec = planned.restSeconds
        startWeightG = planned.startWeight?.grams
        targetDurationSec = planned.targetDurationSeconds
    }

    func toDomainModel() throws -> PlannedExercise {
        return PlannedExercise(
            id: id,
            programDayId: programDayId,
            exerciseId: exerciseId,
            position: position,
            targetSets: targetSets,
            targetReps: try RepRange.fromColumns(min: targetRepsMin, max: targetRepsMax, table: Self.databaseTableName),
            restSeconds: restSec,
            startWeight: startWeightG.map { grams in
                return Weight(grams: grams)
            },
            targetDurationSeconds: targetDurationSec
        )
    }
}
