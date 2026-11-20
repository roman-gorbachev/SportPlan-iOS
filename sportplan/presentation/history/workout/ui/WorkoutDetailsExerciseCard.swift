import DesignSystem
import Foundation
import SwiftUI

struct WorkoutDetailsExerciseCard: View {
    private static let headerMinimumHeight: CGFloat = 52

    let item: WorkoutDetailsExerciseItem
    let onOpenExercise: (UUID) -> Void

    var body: some View {
        return VStack(spacing: .zero) {
            Button {
                onOpenExercise(item.exerciseId)
            } label: {
                return HStack(spacing: Spacing.s) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(item.name)
                            .appStyle(Typography.headline)
                            .foregroundStyle(Palette.textPrimary)
                        Text(item.goal)
                            .appStyle(Typography.footnote)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    Spacer(minLength: Spacing.xs)
                    Image(systemName: "chevron.right")
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textTertiary)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.xs)
                .frame(minHeight: Self.headerMinimumHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Divider()
                .overlay(Palette.separator)
                .padding(.leading, Spacing.m)
            ForEach(item.sets) { set in
                return WorkoutDetailsSetRow(item: set)
            }
        }
        .padding(.bottom, Spacing.xs)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}
