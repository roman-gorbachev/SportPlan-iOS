import Domain
import Foundation

extension PlannedExerciseTargets {
    mutating func apply(_ step: PlannedExerciseTargetsStep, scale: WeightScale?) {
        switch step {
        case .incrementSets:
            incrementSets()
        case .decrementSets:
            decrementSets()
        case .incrementMinimumReps:
            incrementMinimumReps()
        case .decrementMinimumReps:
            decrementMinimumReps()
        case .incrementMaximumReps:
            incrementMaximumReps()
        case .decrementMaximumReps:
            decrementMaximumReps()
        case .incrementRest:
            incrementRest()
        case .decrementRest:
            decrementRest()
        case .incrementStartWeight:
            if let scale {
                incrementStartWeight(on: scale)
            }
        case .decrementStartWeight:
            if let scale {
                decrementStartWeight(on: scale)
            }
        case .incrementDuration:
            incrementDuration()
        case .decrementDuration:
            decrementDuration()
        }
    }

    func uiData(for metric: ExerciseMetric, scale: WeightScale?) -> PlannedExerciseTargetsUiData {
        let duration = durationSeconds ?? .zero
        return PlannedExerciseTargetsUiData(
            setsText: sets.formatted(),
            setsAccessibilityText: ProgramFormatting.setsText(sets),
            canIncrementSets: canIncrementSets,
            canDecrementSets: canDecrementSets,
            showsReps: reps != nil,
            minimumRepsText: reps?.min.formatted() ?? "",
            maximumRepsText: reps?.max.formatted() ?? "",
            canIncrementMinimumReps: canIncrementMinimumReps,
            canDecrementMinimumReps: canDecrementMinimumReps,
            canIncrementMaximumReps: canIncrementMaximumReps,
            canDecrementMaximumReps: canDecrementMaximumReps,
            restText: RestFormatting.clock(seconds: restSeconds),
            restAccessibilityText: RestFormatting.spoken(seconds: restSeconds),
            canIncrementRest: canIncrementRest,
            canDecrementRest: canDecrementRest,
            startWeight: startWeightUiData(for: metric, scale: scale),
            showsDuration: durationSeconds != nil,
            durationText: RestFormatting.clock(seconds: duration),
            durationAccessibilityText: RestFormatting.spoken(seconds: duration),
            canIncrementDuration: canIncrementDuration,
            canDecrementDuration: canDecrementDuration
        )
    }

    private func startWeightUiData(for metric: ExerciseMetric, scale: WeightScale?) -> PlannedExerciseStartWeightUiData? {
        guard metric == .weightReps, let scale else {
            return nil
        }
        let weight = WeightFormatting.kilograms(startWeight(on: scale))
        let valueText = String(localized: "goals.startWeight.value \(weight)")
        return PlannedExerciseStartWeightUiData(
            title: scale.isAddedWeight ? String(localized: "goals.startWeight.added") : String(localized: "goals.startWeight"),
            valueText: valueText,
            accessibilityText: valueText,
            canIncrement: canIncrementStartWeight(on: scale),
            canDecrement: canDecrementStartWeight(on: scale)
        )
    }
}
