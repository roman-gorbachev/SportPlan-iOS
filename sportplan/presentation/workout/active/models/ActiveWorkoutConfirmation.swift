import Foundation

enum ActiveWorkoutConfirmation {
    case finish(incompleteSetCount: Int)
    case discardEmpty
    case cancel
    case removeExercise(workoutExerciseId: UUID, name: String, completedSetCount: Int)
}
