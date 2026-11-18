public struct LibraryExercise: Identifiable, Hashable, Sendable {
    public let exercise: Exercise
    public let equipment: Equipment?

    public init(exercise: Exercise, equipment: Equipment?) {
        self.exercise = exercise
        self.equipment = equipment
    }

    public var id: Exercise.ID {
        return exercise.id
    }

    public var loadKind: ExerciseLoadKind {
        guard let equipment else {
            return .bodyweight
        }
        return .equipment(equipment.kind)
    }
}
