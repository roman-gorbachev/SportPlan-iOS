import Domain
import Foundation

enum WorkoutDetailsUiMapper {
    private static let firstSetNumber = 1

    static func makeData(_ detail: FinishedWorkoutDetail, isShowingDeleteError: Bool) -> WorkoutDetailsUiData {
        let workout = detail.workout
        let note = workout.workout.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        return WorkoutDetailsUiData(
            meta: HistoryFormatting.detailsMeta(workout),
            title: HistoryFormatting.detailsTitle(workout.workout.programDay),
            durationValue: HistoryFormatting.minutes(workout.durationSeconds).formatted(),
            setCountValue: workout.workingSetCount.formatted(),
            recordCountValue: detail.recordCount.formatted(),
            hasRecords: detail.recordCount > .zero,
            exercises: workout.exercises.map { item in
                return makeExercise(item, recordSetIds: detail.recordSetIds)
            },
            note: note?.isEmpty == false ? note : nil,
            isShowingDeleteError: isShowingDeleteError
        )
    }

    private static func makeExercise(_ item: FinishedWorkoutExercise, recordSetIds: Set<UUID>) -> WorkoutDetailsExerciseItem {
        return WorkoutDetailsExerciseItem(
            id: item.id,
            exerciseId: item.exercise.id,
            name: item.exercise.exercise.name,
            goal: goalText(item),
            sets: item.sets.enumerated().map { index, entry in
                return makeSet(entry, number: index + firstSetNumber, exercise: item.exercise, isRecord: recordSetIds.contains(entry.id))
            }
        )
    }

    private static func makeSet(_ entry: SetEntry, number: Int, exercise: LibraryExercise, isRecord: Bool) -> WorkoutDetailsSetItem {
        let value = WorkoutFormatting.setSummary(entry, exercise: exercise)
        var spokenParts = [String(localized: "workout.editor.title \(number)")]
        if entry.isWarmup {
            spokenParts.append(String(localized: "workout.set.warmup"))
        }
        spokenParts.append(value)
        if isRecord {
            spokenParts.append(String(localized: "workout.set.record"))
        }
        return WorkoutDetailsSetItem(
            id: entry.id,
            number: number.formatted(),
            value: value,
            isWarmup: entry.isWarmup,
            isRecord: isRecord,
            accessibilityLabel: spokenParts.joined(separator: String(localized: "format.listSeparator"))
        )
    }

    private static func goalText(_ item: FinishedWorkoutExercise) -> String {
        let target = item.workoutExercise
        guard let sets = target.targetSets else {
            return ProgramFormatting.setsText(item.workingSets.count)
        }
        return ProgramFormatting.targetText(PlannedExerciseTargets(
            sets: sets,
            reps: target.targetReps,
            restSeconds: target.restSeconds,
            durationSeconds: target.targetDurationSeconds
        ))
    }
}
