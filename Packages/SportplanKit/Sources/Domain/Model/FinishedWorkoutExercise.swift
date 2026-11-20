import Foundation

public struct FinishedWorkoutExercise: Identifiable, Hashable, Sendable {
    public let workoutExercise: WorkoutExercise
    public let exercise: LibraryExercise
    public let sets: [SetEntry]

    public init(workoutExercise: WorkoutExercise, exercise: LibraryExercise, sets: [SetEntry]) {
        self.workoutExercise = workoutExercise
        self.exercise = exercise
        self.sets = sets
    }

    public var id: UUID {
        return workoutExercise.id
    }

    public var workingSets: [SetEntry] {
        return sets.filter(RecordBaseline.counts)
    }
}
