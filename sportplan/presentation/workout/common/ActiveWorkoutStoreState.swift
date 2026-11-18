import Domain

enum ActiveWorkoutStoreState: Sendable {
    case loading
    case noWorkout
    case active(workout: ActiveWorkout)
    case error(error: any Error)

    var workout: ActiveWorkout? {
        guard case let .active(workout) = self else {
            return nil
        }
        return workout
    }
}
