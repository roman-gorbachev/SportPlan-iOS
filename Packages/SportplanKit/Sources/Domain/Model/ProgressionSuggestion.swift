public enum ProgressionSuggestion {
    public static func weight(for item: ActiveWorkoutExercise) -> Weight? {
        return weight(
            exercise: item.exercise,
            previousWorkoutExercise: item.previousWorkoutExercise,
            previousWorkingSets: item.previousWorkingSets
        )
    }

    public static func weight(
        exercise: LibraryExercise,
        previousWorkoutExercise: WorkoutExercise?,
        previousWorkingSets: [SetEntry]
    ) -> Weight? {
        guard
            exercise.metric == .weightReps,
            let equipment = exercise.equipment,
            equipment.weightStep > .zero,
            let previous = previousWorkoutExercise,
            let targetSets = previous.targetSets,
            let targetReps = previous.targetReps
        else {
            return nil
        }
        let previousSets = previousWorkingSets.filter { entry in
            return entry.isCompleted
        }
        guard previousSets.count >= targetSets else {
            return nil
        }
        let reachedTopOfRange = previousSets.allSatisfy { entry in
            guard let reps = entry.reps else {
                return false
            }
            return reps >= targetReps.max
        }
        guard reachedTopOfRange, let heaviest = previousSets.map(\.weight).max() else {
            return nil
        }
        return heaviest + equipment.weightStep
    }
}
