import Domain
import Foundation
import GRDB

nonisolated struct SetEntryRecord: AppRecord {
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

    init(_ entry: SetEntry) {
        id = entry.id
        workoutExerciseId = entry.workoutExerciseId
        position = entry.position
        weightG = entry.weight.grams
        reps = entry.reps
        durationSec = entry.durationSeconds
        isWarmup = entry.isWarmup
        startedAt = entry.startedAt
        completedAt = entry.completedAt
    }

    func toDomainModel() -> SetEntry {
        return SetEntry(
            id: id,
            workoutExerciseId: workoutExerciseId,
            position: position,
            weight: Weight(grams: weightG),
            reps: reps,
            durationSeconds: durationSec,
            isWarmup: isWarmup,
            startedAt: startedAt,
            completedAt: completedAt
        )
    }
}
