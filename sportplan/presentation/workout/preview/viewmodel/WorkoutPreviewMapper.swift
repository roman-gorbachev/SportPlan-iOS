import Domain
import Foundation

enum WorkoutPreviewMapper {
    static func makeData(_ preview: WorkoutPreview, isStarting: Bool, isShowingError: Bool) -> WorkoutPreviewUiData {
        let day = preview.detail.day
        let lastWorkout = preview.lastWorkoutAt.map { date in
            return String(localized: "workout.start.lastTime \(WorkoutFormatting.shortDate(date))")
        } ?? String(localized: "workout.never")
        return WorkoutPreviewUiData(
            label: day.label.map(WorkoutFormatting.dayLabel),
            name: day.name,
            programName: preview.detail.programName,
            lastWorkout: lastWorkout,
            exercises: preview.exercises.map(makeItem),
            tip: preview.tip.map(tipText),
            isStarting: isStarting,
            isShowingError: isShowingError
        )
    }

    private static func makeItem(_ exercise: WorkoutPreviewExercise) -> WorkoutPreviewExerciseItem {
        let targets = displayedTargets(exercise)
        let target = ProgramFormatting.targetText(targets)
        let spokenTarget = ProgramFormatting.targetSpokenText(targets)
        guard let weight = weightText(exercise) else {
            return WorkoutPreviewExerciseItem(
                id: exercise.id,
                name: exercise.item.exercise.exercise.name,
                plan: target,
                planAccessibility: spokenTarget
            )
        }
        return WorkoutPreviewExerciseItem(
            id: exercise.id,
            name: exercise.item.exercise.exercise.name,
            plan: String(localized: "format.dotSeparated \(target) \(weight)"),
            planAccessibility: [spokenTarget, weight].joined(separator: String(localized: "format.listSeparator"))
        )
    }

    private static func displayedTargets(_ exercise: WorkoutPreviewExercise) -> PlannedExerciseTargets {
        var targets = exercise.item.plannedExercise.targets
        targets.sets = exercise.plannedSets.count
        if exercise.item.exercise.exercise.metric == .duration {
            targets.durationSeconds = exercise.plannedSets.first?.durationSeconds ?? targets.durationSeconds
        }
        return targets
    }

    private static func weightText(_ exercise: WorkoutPreviewExercise) -> String? {
        guard
            exercise.item.exercise.exercise.metric == .weightReps,
            let first = exercise.plannedSets.first
        else {
            return nil
        }
        let kilograms = WeightFormatting.kilograms(first.weight)
        guard exercise.item.exercise.equipment == nil else {
            return String(localized: "workout.preview.weight \(kilograms)")
        }
        guard first.weight > .zero else {
            return nil
        }
        return String(localized: "workout.preview.addedWeight \(kilograms)")
    }

    private static func tipText(_ tip: WorkoutPreviewTip) -> String {
        switch tip {
        case let .progression(exerciseName, weight):
            return String(localized: "workout.preview.tip.progression \(exerciseName) \(WeightFormatting.kilograms(weight))")
        case .firstWorkout:
            return String(localized: "workout.preview.tip.first")
        case let .longBreak(days):
            return String(localized: "workout.preview.tip.longBreak \(days)")
        }
    }
}
