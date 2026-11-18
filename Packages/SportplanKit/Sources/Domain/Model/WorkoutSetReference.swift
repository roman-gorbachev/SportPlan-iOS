public struct WorkoutSetReference: Hashable, Sendable {
    public let exercise: ActiveWorkoutExercise
    public let entry: SetEntry

    public init(exercise: ActiveWorkoutExercise, entry: SetEntry) {
        self.exercise = exercise
        self.entry = entry
    }

    public var number: Int? {
        return exercise.number(of: entry)
    }
}
