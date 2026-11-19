import DesignSystem
import SwiftUI

struct ExerciseSessionRow: View {
    let item: ExerciseCardSessionItem

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                Text(item.date)
                    .appStyle(Typography.callout)
                    .foregroundStyle(Palette.textPrimary)
                if item.isRecord {
                    RecordBadge(title: String(localized: "workout.set.record"), showsIcon: false)
                }
            }
            Text(item.sets)
                .appStyle(Typography.numeralS)
                .foregroundStyle(Palette.textPrimary)
        }
        .padding(.vertical, Spacing.s)
        .padding(.horizontal, Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.accessibilityLabel)
    }
}
