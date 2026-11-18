public enum WorkoutError: Error, Equatable, Sendable {
    case alreadyActive
    case noActiveWorkout
    case notFound
    case exerciseAlreadyInWorkout
    case exerciseUnavailable
    case invalidSet
}
