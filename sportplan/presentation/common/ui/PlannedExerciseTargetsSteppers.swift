import DesignSystem
import SwiftUI

struct PlannedExerciseTargetsSteppers: View {
    let data: PlannedExerciseTargetsUiData
    let onStep: (PlannedExerciseTargetsStep) -> Void

    var body: some View {
        return VStack(spacing: Spacing.s) {
            ValueStepper(
                title: String(localized: "goals.sets"),
                value: data.setsText,
                accessibilityValue: data.setsAccessibilityText,
                canDecrement: data.canDecrementSets,
                canIncrement: data.canIncrementSets,
                onDecrement: { onStep(.decrementSets) },
                onIncrement: { onStep(.incrementSets) }
            )
            if data.showsReps {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.s) {
                        minimumRepsStepper
                        maximumRepsStepper
                    }
                    VStack(spacing: Spacing.s) {
                        minimumRepsStepper
                        maximumRepsStepper
                    }
                }
            }
            if data.showsDuration {
                ValueStepper(
                    title: String(localized: "goals.duration"),
                    value: data.durationText,
                    accessibilityValue: data.durationAccessibilityText,
                    canDecrement: data.canDecrementDuration,
                    canIncrement: data.canIncrementDuration,
                    onDecrement: { onStep(.decrementDuration) },
                    onIncrement: { onStep(.incrementDuration) }
                )
            }
            if let startWeight = data.startWeight {
                ValueStepper(
                    title: startWeight.title,
                    value: startWeight.valueText,
                    accessibilityValue: startWeight.accessibilityText,
                    canDecrement: startWeight.canDecrement,
                    canIncrement: startWeight.canIncrement,
                    onDecrement: { onStep(.decrementStartWeight) },
                    onIncrement: { onStep(.incrementStartWeight) }
                )
            }
        }
    }

    private var minimumRepsStepper: some View {
        return ValueStepper(
            title: String(localized: "goals.reps.from"),
            accessibilityTitle: String(localized: "goals.reps.from.accessibility"),
            value: data.minimumRepsText,
            accessibilityValue: data.minimumRepsText,
            canDecrement: data.canDecrementMinimumReps,
            canIncrement: data.canIncrementMinimumReps,
            onDecrement: { onStep(.decrementMinimumReps) },
            onIncrement: { onStep(.incrementMinimumReps) }
        )
    }

    private var maximumRepsStepper: some View {
        return ValueStepper(
            title: String(localized: "goals.reps.to"),
            accessibilityTitle: String(localized: "goals.reps.to.accessibility"),
            value: data.maximumRepsText,
            accessibilityValue: data.maximumRepsText,
            canDecrement: data.canDecrementMaximumReps,
            canIncrement: data.canIncrementMaximumReps,
            onDecrement: { onStep(.decrementMaximumReps) },
            onIncrement: { onStep(.incrementMaximumReps) }
        )
    }
}
