public struct PlannedExerciseItem: Identifiable, Hashable, Sendable {
    public let plannedExercise: PlannedExercise
    public let exercise: LibraryExercise

    public init(plannedExercise: PlannedExercise, exercise: LibraryExercise) {
        self.plannedExercise = plannedExercise
        self.exercise = exercise
    }

    public var id: PlannedExercise.ID {
        return plannedExercise.id
    }
}
