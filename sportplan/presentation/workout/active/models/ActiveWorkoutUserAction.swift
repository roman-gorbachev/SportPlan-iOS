import Foundation

enum ActiveWorkoutUserAction {
    case openSettings
    case addExercise
    case requestCancel
    case requestFinish
    case editSet(id: UUID)
    case tapSetAction(id: UUID)
    case addSet(workoutExerciseId: UUID, isWarmup: Bool)
    case removeSet(id: UUID)
    case updateNote(String)
    case closeEditor
    case incrementWeight
    case decrementWeight
    case incrementReps
    case decrementReps
    case copyLastWorkoutSet
    case saveEditor
    case adjustRest(seconds: Int)
    case skipRest
    case confirm(ActiveWorkoutConfirmation)
    case dismissConfirmation
    case dismissError
}
