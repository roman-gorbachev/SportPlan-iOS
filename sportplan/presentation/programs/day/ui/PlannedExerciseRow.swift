import DesignSystem
import SwiftUI

struct PlannedExerciseRow: View {
    let item: PlannedExerciseRowItem
    let showsChevron: Bool

    var body: some View {
        return HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.name)
                    .appStyle(Typography.body)
                    .foregroundStyle(Palette.textPrimary)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.xs) {
                        target
                        detail
                    }
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        target
                        detail
                    }
                }
            }
            Spacer(minLength: Spacing.s)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.name)
        .accessibilityValue(String(localized: "format.commaSeparated \(item.targetAccessibilityText) \(item.detailText)"))
    }

    private var target: some View {
        return Text(item.targetText)
            .appStyle(Typography.numeralS)
            .foregroundStyle(Palette.textPrimary)
    }

    private var detail: some View {
        return Text(item.detailText)
            .appStyle(Typography.footnote)
            .foregroundStyle(Palette.textSecondary)
    }
}
