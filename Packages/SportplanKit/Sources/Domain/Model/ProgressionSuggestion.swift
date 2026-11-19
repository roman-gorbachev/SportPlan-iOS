public enum ProgressionSuggestion {
    public static func weight(for item: ActiveWorkoutExercise) -> Weight? {
        guard
            item.exercise.metric == .weightReps,
            let equipment = item.exercise.equipment,
            equipment.weightStep > .zero,
            let previous = item.previousWorkoutExercise,
            let targetSets = previous.targetSets,
            let targetReps = previous.targetReps
        else {
            return nil
        }
        let previousSets = item.previousWorkingSets.filter { entry in
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
