import DesignSystem
import SwiftUI

struct PlannedExerciseGoalsScreen: View {
    let data: PlannedExerciseGoalsUiData
    let onStep: (PlannedExerciseTargetsStep) -> Void
    let onRemove: () -> Void
    let onDismissError: () -> Void

    var body: some View {
        return Form {
            Section {
                PlannedExerciseTargetsSteppers(data: data.targets, onStep: onStep)
            } footer: {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    hint(data.targets.showsReps ? String(localized: "goals.reps.hint") : String(localized: "goals.timed.hint"))
                    if data.targets.startWeight != nil {
                        hint(String(localized: "goals.startWeight.hint"))
                    }
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            Section {
                ValueStepper(
                    title: String(localized: "goals.rest"),
                    value: data.targets.restText,
                    accessibilityValue: data.targets.restAccessibilityText,
                    canDecrement: data.targets.canDecrementRest,
                    canIncrement: data.targets.canIncrementRest,
                    onDecrement: { onStep(.decrementRest) },
                    onIncrement: { onStep(.incrementRest) }
                )
            } footer: {
                hint(data.restHint)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            Section {
                Button(String(localized: "goals.remove"), role: .destructive, action: onRemove)
                    .foregroundStyle(Palette.destructive)
                    .frame(maxWidth: .infinity)
            }
            .appListRow()
        }
        .appStyle(Typography.body)
        .appGroupedList()
        .alert(
            String(localized: "common.error.title"),
            isPresented: Binding(get: { return data.isShowingError }, set: { isPresented in
                if !isPresented {
                    onDismissError()
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        } message: {
            Text(String(localized: "common.error.message"))
        }
    }

    private func hint(_ text: String) -> some View {
        return Text(text)
            .appStyle(Typography.footnote)
            .foregroundStyle(Palette.textSecondary)
    }
}
