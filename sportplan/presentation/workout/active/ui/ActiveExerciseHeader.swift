import DesignSystem
import SwiftUI

struct ActiveExerciseHeader: View {
    let exercise: ActiveExerciseItem

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(exercise.name)
                .appStyle(Typography.title)
                .foregroundStyle(Palette.textPrimary)
            Text(exercise.summary)
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
        }
        .textCase(nil)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
