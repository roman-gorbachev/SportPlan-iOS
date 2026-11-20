public struct ArchivedExercise: Identifiable, Hashable, Sendable {
    public let exercise: LibraryExercise
    public let workoutCount: Int

    public init(exercise: LibraryExercise, workoutCount: Int) {
        self.exercise = exercise
        self.workoutCount = workoutCount
    }

    public var id: Exercise.ID {
        return exercise.id
    }
}
