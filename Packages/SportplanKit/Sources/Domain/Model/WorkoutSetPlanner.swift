import Foundation

public enum WorkoutSetPlanner {
    public static func plannedSets(
        for exercise: LibraryExercise,
        workoutExerciseId: UUID,
        targetSets: Int?,
        targetReps: RepRange?,
        startWeight: Weight? = nil,
        targetDurationSeconds: Int? = nil,
        previousSets: [SetEntry]
    ) -> [SetEntry] {
        let previousWorking = previousSets.filter { entry in
            return !entry.isWarmup
        }
        let drafts: [SetEntryDraft]
        switch (targetSets, previousWorking.last) {
        case let (count?, lastPrevious?):
            drafts = (0..<count).map { index in
                let source = index < previousWorking.count ? previousWorking[index] : lastPrevious
                return plannedDraft(copying: source, metric: exercise.metric)
            }
        case let (count?, nil):
            let draft = defaultDraft(
                for: exercise,
                targetReps: targetReps,
                startWeight: startWeight,
                durationSeconds: targetDurationSeconds
            )
            drafts = Array(repeating: draft, count: count)
        case (nil, .some):
            drafts = previousWorking.map { entry in
                return plannedDraft(copying: entry, metric: exercise.metric)
            }
        case (nil, nil):
            drafts = [
                defaultDraft(
                    for: exercise,
                    targetReps: targetReps,
                    startWeight: startWeight,
                    durationSeconds: targetDurationSeconds
                ),
            ]
        }
        return drafts.enumerated().map { position, draft in
            return makeEntry(draft: draft, workoutExerciseId: workoutExerciseId, position: position, isWarmup: false)
        }
    }

    public static func newSet(in item: ActiveWorkoutExercise, isWarmup: Bool) -> SetEntry {
        let sameKind = item.sets.filter { entry in
            return entry.isWarmup == isWarmup
        }
        let draft: SetEntryDraft
        if let last = sameKind.last {
            draft = plannedDraft(copying: last, metric: item.exercise.metric)
        } else if !isWarmup, let previous = item.previousWorkingSets.first {
            draft = plannedDraft(copying: previous, metric: item.exercise.metric)
        } else {
            draft = defaultDraft(
                for: item.exercise,
                targetReps: item.workoutExercise.targetReps,
                durationSeconds: item.workoutExercise.targetDurationSeconds
            )
        }
        return makeEntry(
            draft: draft,
            workoutExerciseId: item.id,
            position: item.insertionPosition(isWarmup: isWarmup),
            isWarmup: isWarmup
        )
    }

    public static func defaultDraft(
        for exercise: LibraryExercise,
        targetReps: RepRange?,
        startWeight: Weight? = nil,
        durationSeconds: Int? = nil
    ) -> SetEntryDraft {
        switch exercise.metric {
        case .weightReps:
            let reps = targetReps ?? PlannedExerciseTargets(defaultsFor: exercise.exercise).reps
            let weight = Swift.max(startWeight ?? exercise.minimumWeight, exercise.minimumWeight)
            return SetEntryDraft(weight: weight, reps: reps?.min, durationSeconds: nil)
        case .duration:
            return SetEntryDraft(weight: exercise.minimumWeight, reps: nil, durationSeconds: durationSeconds)
        }
    }

    private static func plannedDraft(copying entry: SetEntry, metric: ExerciseMetric) -> SetEntryDraft {
        switch metric {
        case .weightReps:
            return SetEntryDraft(weight: entry.weight, reps: entry.reps, durationSeconds: nil)
        case .duration:
            return SetEntryDraft(weight: entry.weight, reps: nil, durationSeconds: entry.durationSeconds)
        }
    }

    private static func makeEntry(
        draft: SetEntryDraft,
        workoutExerciseId: UUID,
        position: Int,
        isWarmup: Bool
    ) -> SetEntry {
        return SetEntry(
            id: UUID(),
            workoutExerciseId: workoutExerciseId,
            position: position,
            weight: draft.weight,
            reps: draft.reps,
            durationSeconds: draft.durationSeconds,
            isWarmup: isWarmup,
            startedAt: nil,
            completedAt: nil
        )
    }
}
