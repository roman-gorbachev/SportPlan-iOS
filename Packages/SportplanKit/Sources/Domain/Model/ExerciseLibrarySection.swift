public struct ExerciseLibrarySection: Hashable, Sendable {
    public let category: ExerciseCategory
    public let exercises: [LibraryExercise]

    public init(category: ExerciseCategory, exercises: [LibraryExercise]) {
        self.category = category
        self.exercises = exercises
    }
}
