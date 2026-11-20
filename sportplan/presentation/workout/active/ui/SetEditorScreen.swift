import DesignSystem
import SwiftUI

struct SetEditorScreen: View {
    private static let repsStep = 1

    let data: SetEditorUiData
    let onAction: (ActiveWorkoutUserAction) -> Void

    var body: some View {
        return NavigationStack {
            return ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    LargeValueStepper(
                        title: data.weight.title,
                        caption: data.weight.caption,
                        value: data.weight.value,
                        decrementLabel: data.weight.decrementLabel,
                        incrementLabel: data.weight.incrementLabel,
                        canDecrement: data.weight.canDecrement,
                        canIncrement: true,
                        onDecrement: { onAction(.decrementWeight) },
                        onIncrement: { onAction(.incrementWeight) }
                    )
                    LargeValueStepper(
                        title: String(localized: "workout.editor.reps"),
                        caption: String(localized: "workout.editor.repsStep \(Self.repsStep)"),
                        value: data.reps,
                        decrementLabel: String(localized: "workout.editor.reps.decrement \(Self.repsStep)"),
                        incrementLabel: String(localized: "workout.editor.reps.increment \(Self.repsStep)"),
                        canDecrement: data.canDecrementReps,
                        canIncrement: true,
                        onDecrement: { onAction(.decrementReps) },
                        onIncrement: { onAction(.incrementReps) }
                    )
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: Spacing.xs) {
                            buttons
                        }
                        VStack(spacing: Spacing.xs) {
                            buttons
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
                .padding(Spacing.m)
            }
            .background(Palette.surface)
            .navigationTitle(data.title)
            .navigationSubtitle(data.exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    return Button(String(localized: "common.cancel")) {
                        onAction(.closeEditor)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var buttons: some View {
        Button {
            onAction(.copyLastWorkoutSet)
        } label: {
            return Label(String(localized: "workout.editor.copyLastWorkout"), systemImage: "arrow.uturn.down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SunkenButtonStyle())
        .disabled(!data.canCopyLastWorkout)
        Button {
            onAction(.saveEditor)
        } label: {
            return Text(String(localized: "workout.editor.save"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(InkButtonStyle())
    }
}

#Preview {
    FontRegistry.registerFonts()
    let data = SetEditorUiData(
        id: UUID(),
        title: "Подход 3",
        exerciseName: "Жим лёжа",
        weight: SetEditorWeightField(
            title: "Вес, кг",
            caption: "шаг 2,5 · Олимпийский гриф",
            value: "65",
            decrementLabel: "Уменьшить вес на 2,5 кг",
            incrementLabel: "Увеличить вес на 2,5 кг",
            canDecrement: true
        ),
        reps: "8",
        canDecrementReps: true,
        canCopyLastWorkout: true
    )
    return Color.clear
        .sheet(isPresented: .constant(true)) {
            return SetEditorScreen(data: data, onAction: { _ in })
        }
}
