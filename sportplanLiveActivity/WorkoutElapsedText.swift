import DesignSystem
import SwiftUI

struct WorkoutElapsedText: View {
    let startedAt: Date

    var body: some View {
        return HStack(spacing: Spacing.xxs) {
            Text("activity.workout.elapsed")
            Text(startedAt, style: .timer)
                .monospacedDigit()
        }
        .appStyle(Typography.caption)
        .foregroundStyle(Palette.textSecondary)
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}
