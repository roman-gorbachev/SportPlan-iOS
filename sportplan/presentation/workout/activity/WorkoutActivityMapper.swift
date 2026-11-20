import Domain
import Foundation
import WorkoutActivity

enum WorkoutActivityMapper {
    static func makeAttributes(workout: ActiveWorkout) -> WorkoutActivityAttributes {
        return WorkoutActivityAttributes(workoutId: workout.id, startedAt: workout.workout.startedAt)
    }

    static func makeContent(workout: ActiveWorkout, rest: RestPeriod?, plates: [Plate]) -> WorkoutActivityContent {
        if let running = workout.runningSet {
            return makeTimedSetContent(running)
        }
        let current = workout.currentSet
        let loadText = current.map { current in
            return WorkoutFormatting.setSummary(current.entry, exercise: current.exercise.exercise)
        } ?? ""
        return WorkoutActivityContent(
            phase: phase(current: current, rest: rest),
            exerciseName: current?.exercise.exercise.exercise.name ?? "",
            setText: current.map(setText) ?? "",
            loadText: loadText,
            nextText: current == nil ? "" : String(localized: "activity.next \(loadText)"),
            readyText: readyText(current),
            restStartedAt: rest?.startedAt,
            restEndsAt: rest?.endsAt,
            plates: current.map(activityPlates(plates: plates)) ?? []
        )
    }

    static func staleDate(workout: ActiveWorkout, rest: RestPeriod?) -> Date? {
        if let running = workout.runningSet {
            return running.entry.targetEndsAt
        }
        return rest?.endsAt
    }

    private static func makeTimedSetContent(_ running: WorkoutSetReference) -> WorkoutActivityContent {
        return WorkoutActivityContent(
            phase: .timedSet,
            exerciseName: running.exercise.exercise.exercise.name,
            setText: setText(running),
            loadText: WorkoutFormatting.setSummary(running.entry, exercise: running.exercise.exercise),
            nextText: "",
            readyText: "",
            restStartedAt: nil,
            restEndsAt: nil,
            plates: [],
            setStartedAt: running.entry.startedAt,
            setTargetEndsAt: running.entry.targetEndsAt
        )
    }

    private static func phase(current: WorkoutSetReference?, rest: RestPeriod?) -> WorkoutActivityPhase {
        if rest != nil {
            return .rest
        }
        return current == nil ? .finishedSets : .set
    }

    private static func setText(_ current: WorkoutSetReference) -> String {
        guard !current.entry.isWarmup, let number = current.number else {
            return String(localized: "workout.set.warmup")
        }
        let label = String(localized: "activity.set \(number)")
        let item = current.exercise
        guard item.exercise.metric == .weightReps, let reps = item.workoutExercise.targetReps else {
            return label
        }
        let target = String(localized: "workout.active.reps \(ProgramFormatting.repsText(reps))")
        return String(localized: "format.dotSeparated \(label) \(target)")
    }

    private static func readyText(_ current: WorkoutSetReference?) -> String {
        guard let current, let number = current.number else {
            return String(localized: "rest.notification.finish")
        }
        return String(localized: "rest.notification.next \(current.exercise.exercise.exercise.name) \(number)")
    }

    private static func activityPlates(plates: [Plate]) -> (WorkoutSetReference) -> [WorkoutActivityPlate] {
        return { current in
            guard let loading = PlateLoading(weight: current.entry.weight, exercise: current.exercise.exercise, plates: plates) else {
                return []
            }
            return loading.platesPerSide.map { plate in
                return WorkoutActivityPlate(rgb: plate.color.rgb, kilograms: plate.weight.kilograms)
            }
        }
    }
}
