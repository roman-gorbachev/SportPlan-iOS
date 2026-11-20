import DesignSystem
import SwiftUI

struct WorkoutPreviewExerciseRow: View {
    let exercise: WorkoutPreviewExerciseItem

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(exercise.name)
                .appStyle(Typography.body)
                .foregroundStyle(Palette.textPrimary)
            Text(exercise.plan)
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(exercise.name)
        .accessibilityValue(exercise.planAccessibility)
    }
}
