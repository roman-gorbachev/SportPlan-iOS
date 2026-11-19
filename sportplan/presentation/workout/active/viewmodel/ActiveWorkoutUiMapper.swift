import DesignSystem
import Domain
import Foundation

enum ActiveWorkoutUiMapper {
    private static let firstSetNumber = 1
    private static let missingReps = 0

    static func makeData(
        workout: ActiveWorkout,
        rest: RestPeriod?,
        plates: [Plate],
        note: String,
        editor: SetEditorUiData?,
        confirmation: ActiveWorkoutConfirmation?,
        isShowingError: Bool
    ) -> ActiveWorkoutUiData {
        let currentSetId = workout.currentSet?.entry.id
        let restTimer = rest.map { rest in
            return RestTimerMapper.makeItem(workout: workout, rest: rest)
        }
        let restExerciseId = workout.restTrigger?.exercise.id
        return ActiveWorkoutUiData(
            title: workout.workout.programDay?.name ?? String(localized: "workout.active.untitled"),
            subtitle: subtitle(workout),
            startedAt: workout.workout.startedAt,
            exercises: workout.exercises.map { item in
                return makeExercise(
                    item,
                    plates: plates,
                    currentSetId: currentSetId,
                    restTimer: item.id == restExerciseId ? restTimer : nil
                )
            },
            note: note,
            editor: editor,
            confirmation: confirmation,
            isShowingError: isShowingError
        )
    }

    static func makeEditor(item: ActiveWorkoutExercise, entry: SetEntry, draft: SetEntryDraft) -> SetEditorUiData {
        let exercise = item.exercise
        let step = WeightFormatting.kilograms(exercise.weightStep)
        let stepCaption = String(localized: "workout.editor.step \(step)")
        let weightCaption = exercise.equipment.map { equipment in
            return String(localized: "format.dotSeparated \(stepCaption) \(equipment.name)")
        } ?? stepCaption
        let title = entry.isWarmup
            ? String(localized: "workout.editor.warmup")
            : String(localized: "workout.editor.title \(item.number(of: entry) ?? firstSetNumber)")
        return SetEditorUiData(
            id: entry.id,
            title: title,
            exerciseName: exercise.exercise.name,
            weight: SetEditorWeightField(
                title: weightTitle(exercise),
                caption: weightCaption,
                value: WeightFormatting.kilograms(draft.weight),
                decrementLabel: String(localized: "workout.editor.weight.decrement \(step)"),
                incrementLabel: String(localized: "workout.editor.weight.increment \(step)"),
                canDecrement: draft.canDecrementWeight(for: exercise)
            ),
            reps: (draft.reps ?? Self.missingReps).formatted(),
            canDecrementReps: draft.canDecrementReps,
            canCopyLastWorkout: item.previousResult(for: entry) != nil,
            saveTitle: entry.isCompleted ? String(localized: "workout.editor.save") : String(localized: "workout.editor.record")
        )
    }

    private static func subtitle(_ workout: ActiveWorkout) -> String? {
        guard let day = workout.workout.programDay else {
            return nil
        }
        let label = day.label.map(WorkoutFormatting.dayLabel)
        switch (label, workout.programName) {
        case let (label?, programName?):
            return String(localized: "format.dotSeparated \(label) \(programName)")
        case let (label?, nil):
            return label
        case let (nil, programName?):
            return programName
        case (nil, nil):
            return nil
        }
    }

    private static func makeExercise(
        _ item: ActiveWorkoutExercise,
        plates: [Plate],
        currentSetId: UUID?,
        restTimer: RestTimerItem?
    ) -> ActiveExerciseItem {
        let recordSetIds = item.recordSetIds
        return ActiveExerciseItem(
            id: item.id,
            name: item.exercise.exercise.name,
            summary: exerciseSummary(item),
            sets: item.sets.enumerated().map { index, entry in
                return makeRow(
                    entry,
                    number: index + firstSetNumber,
                    item: item,
                    plates: plates,
                    isCurrent: entry.id == currentSetId,
                    isRecord: recordSetIds.contains(entry.id)
                )
            },
            restTimer: restTimer
        )
    }

    private static func exerciseSummary(_ item: ActiveWorkoutExercise) -> String {
        let total = item.workoutExercise.targetSets ?? item.workingSets.count
        let progress = String(localized: "workout.active.progress \(item.completedWorkingSetCount) \(total)")
        guard item.exercise.metric == .weightReps, let reps = item.workoutExercise.targetReps else {
            return progress
        }
        let target = String(localized: "workout.active.reps \(ProgramFormatting.repsText(reps))")
        return String(localized: "format.dotSeparated \(progress) \(target)")
    }

    private static func makeRow(
        _ entry: SetEntry,
        number: Int,
        item: ActiveWorkoutExercise,
        plates: [Plate],
        isCurrent: Bool,
        isRecord: Bool
    ) -> SetRowItem {
        let exercise = item.exercise
        let state = rowState(entry, isCurrent: isCurrent)
        return SetRowItem(
            id: entry.id,
            number: number,
            value: rowValue(entry, exercise: exercise),
            valueAccessibility: valueAccessibility(entry, exercise: exercise),
            isWarmup: entry.isWarmup,
            isRecord: isRecord,
            state: state,
            caption: caption(entry, item: item, state: state),
            plates: rowPlates(entry, exercise: exercise, plates: plates),
            isTimed: exercise.metric == .duration,
            isEditable: exercise.metric == .weightReps
        )
    }

    private static func rowState(_ entry: SetEntry, isCurrent: Bool) -> SetRowState {
        switch entry.state {
        case .completed:
            return .completed
        case .running:
            return .running
        case .planned:
            return isCurrent ? .current : .planned
        }
    }

    private static func rowValue(_ entry: SetEntry, exercise: LibraryExercise) -> SetRowValue {
        let reps = entry.reps?.formatted() ?? String(localized: "workout.set.noValue")
        switch exercise.metric {
        case .duration:
            let text = entry.durationSeconds.map(WorkoutFormatting.duration(seconds:)) ?? String(localized: "workout.set.noDuration")
            return .duration(text: text, runningSince: entry.state == .running ? entry.startedAt : nil)
        case .weightReps:
            guard exercise.equipment != nil else {
                let added = entry.weight > .zero ? WorkoutFormatting.weightText(entry.weight, exercise: exercise) : nil
                return .bodyweightReps(addedWeight: added, reps: reps)
            }
            return .weightReps(weight: WeightFormatting.kilograms(entry.weight), reps: reps)
        }
    }

    private static func valueAccessibility(_ entry: SetEntry, exercise: LibraryExercise) -> String {
        switch exercise.metric {
        case .duration:
            guard let seconds = entry.durationSeconds else {
                return String(localized: "workout.set.noDuration.accessibility")
            }
            return RestFormatting.spoken(seconds: seconds)
        case .weightReps:
            let reps = String(localized: "workout.set.reps.spoken \(entry.reps ?? Self.missingReps)")
            guard exercise.equipment != nil || entry.weight > .zero else {
                return reps
            }
            let weight = String(localized: "workout.set.weight.spoken \(WeightFormatting.kilograms(entry.weight))")
            return String(localized: "format.commaSeparated \(weight) \(reps)")
        }
    }

    private static func caption(_ entry: SetEntry, item: ActiveWorkoutExercise, state: SetRowState) -> String? {
        var parts: [String] = []
        if item.exercise.equipment?.kind == .dumbbell {
            parts.append(String(localized: "workout.set.oneDumbbell"))
        }
        if state == .planned, item.exercise.metric == .weightReps {
            parts.append(String(localized: "workout.set.planned"))
        }
        if state == .running {
            parts.append(String(localized: "workout.set.running"))
        }
        if let previous = item.previousResult(for: entry) {
            parts.append(String(localized: "workout.set.previous \(WorkoutFormatting.setSummary(previous, exercise: item.exercise))"))
        }
        if state == .current, item.exercise.metric == .duration {
            parts.append(String(localized: "workout.set.tapToStart"))
        }
        guard !parts.isEmpty else {
            return nil
        }
        return parts.joined(separator: String(localized: "format.dotSeparator"))
    }

    private static func rowPlates(_ entry: SetEntry, exercise: LibraryExercise, plates: [Plate]) -> SetRowPlates? {
        guard
            let loading = PlateLoading(weight: entry.weight, exercise: exercise, plates: plates),
            !loading.platesPerSide.isEmpty
        else {
            return nil
        }
        let weights = loading.platesPerSide.map { plate in
            return WeightFormatting.kilograms(plate.weight)
        }
        let perSide = String(localized: "workout.plates.perSide \(weights.formatted(.list(type: .and).locale(AppLocale.current)))")
        let remainder = loading.isExact ? nil : WeightFormatting.kilograms(loading.remainderPerSide)
        let accessibilityLabel = remainder.map { remainder in
            return String(localized: "format.commaSeparated \(perSide) \(String(localized: "workout.plates.remainder.spoken \(remainder)"))")
        } ?? perSide
        return SetRowPlates(
            plates: loading.platesPerSide.map { plate in
                return PlateStackItem(rgb: plate.color.rgb, kilograms: plate.weight.kilograms)
            },
            remainder: remainder.map { remainder in
                return String(localized: "workout.plates.remainder \(remainder)")
            },
            accessibilityLabel: accessibilityLabel
        )
    }

    private static func weightTitle(_ exercise: LibraryExercise) -> String {
        guard let equipment = exercise.equipment else {
            return String(localized: "workout.editor.addedWeight")
        }
        guard equipment.kind == .dumbbell else {
            return String(localized: "workout.editor.weight")
        }
        return String(localized: "workout.editor.dumbbellWeight")
    }
}
