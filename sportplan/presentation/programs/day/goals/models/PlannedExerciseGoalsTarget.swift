import Domain
import Foundation

struct PlannedExerciseGoalsTarget: Hashable, Identifiable {
    let plannedExerciseId: UUID
    let exercise: LibraryExercise
    let dayTitle: String
    let targets: PlannedExerciseTargets

    var id: UUID {
        return plannedExerciseId
    }
}
