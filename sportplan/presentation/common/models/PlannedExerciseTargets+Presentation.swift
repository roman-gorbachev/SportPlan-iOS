import Domain
import Foundation

extension PlannedExerciseTargets {
    mutating func apply(_ step: PlannedExerciseTargetsStep) {
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
        }
    }

    var uiData: PlannedExerciseTargetsUiData {
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
            canDecrementRest: canDecrementRest
        )
    }
}
