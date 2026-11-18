import DesignSystem
import SwiftUI

struct WorkoutStartNextDayCard: View {
    let day: WorkoutStartNextDayItem
    let isStarting: Bool
    let onStart: () -> Void

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let label = day.label {
                    Text(label)
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                Text(day.name)
                    .appStyle(Typography.title)
                    .foregroundStyle(Palette.textPrimary)
                Text(day.exercises)
                    .appStyle(Typography.callout)
                    .foregroundStyle(Palette.textSecondary)
                Text(day.lastWorkout)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
            .accessibilityElement(children: .combine)
            Button(action: onStart) {
                return Text(String(localized: "workout.start.begin"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(InkButtonStyle())
            .padding(.top, Spacing.xs)
            .disabled(isStarting)
            .accessibilityLabel(String(localized: "workout.start.begin.accessibility \(day.name)"))
        }
        .padding(.vertical, Spacing.xs)
    }
}
