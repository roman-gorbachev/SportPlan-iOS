import Domain
import Foundation

struct PlannedExerciseGoalsTarget: Hashable, Identifiable {
    let plannedExerciseId: UUID
    let exerciseName: String
    let dayTitle: String
    let exerciseRestSeconds: Int
    let targets: PlannedExerciseTargets

    var id: UUID {
        return plannedExerciseId
    }
}
