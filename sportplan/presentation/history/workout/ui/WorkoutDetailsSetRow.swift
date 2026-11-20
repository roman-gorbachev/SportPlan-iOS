import DesignSystem
import SwiftUI

struct WorkoutDetailsSetRow: View {
    private static let minimumHeight: CGFloat = 36
    private static let numberWidth: CGFloat = 18

    let item: WorkoutDetailsSetItem

    var body: some View {
        return HStack(spacing: Spacing.s) {
            Text(item.number)
                .appStyle(Typography.caption)
                .foregroundStyle(Palette.textSecondary)
                .frame(minWidth: Self.numberWidth, alignment: .leading)
            Text(item.value)
                .appStyle(Typography.numeralS)
                .foregroundStyle(item.isWarmup ? Palette.textSecondary : Palette.textPrimary)
            if item.isWarmup {
                WarmupBadge(title: String(localized: "workout.set.warmup"))
            }
            if item.isRecord {
                RecordBadge(title: String(localized: "workout.set.record"), showsIcon: false)
            }
            Spacer(minLength: .zero)
        }
        .padding(.horizontal, Spacing.m)
        .frame(minHeight: Self.minimumHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.accessibilityLabel)
    }
}
