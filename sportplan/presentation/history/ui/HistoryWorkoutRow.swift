import DesignSystem
import SwiftUI

struct HistoryWorkoutRow: View {
    private static let minimumHeight: CGFloat = 64
    private static let recordDotSize: CGFloat = 8

    let item: HistoryWorkoutItem
    let action: () -> Void

    var body: some View {
        return Button(action: action) {
            return HStack(spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(item.title)
                        .appStyle(Typography.headline)
                        .foregroundStyle(Palette.textPrimary)
                    Text(item.meta)
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer(minLength: Spacing.xs)
                if item.recordCount > .zero {
                    HStack(spacing: Spacing.xxs) {
                        Circle()
                            .fill(Palette.record)
                            .frame(width: Self.recordDotSize, height: Self.recordDotSize)
                        Text(item.recordCountText)
                            .appStyle(Typography.caption)
                            .foregroundStyle(Palette.textPrimary)
                    }
                }
                Image(systemName: "chevron.right")
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(.vertical, Spacing.s)
            .padding(.horizontal, Spacing.m)
            .frame(minHeight: Self.minimumHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }
}
