import DesignSystem
import SwiftUI

struct WorkoutStartDayRow: View {
    let day: WorkoutStartDayItem
    let action: () -> Void

    var body: some View {
        return Button(action: action) {
            return HStack(spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(day.title)
                        .appStyle(Typography.body)
                        .foregroundStyle(Palette.textPrimary)
                    Text(day.subtitle)
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer(minLength: Spacing.s)
                Image(systemName: "play.fill")
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textTertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(String(localized: "workout.start.day.hint"))
    }
}
