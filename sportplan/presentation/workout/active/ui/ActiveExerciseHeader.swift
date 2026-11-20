import DesignSystem
import SwiftUI

struct ActiveExerciseHeader: View {
    private static let menuIconName = "ellipsis"
    private static let menuTapSize: CGFloat = 44

    let exercise: ActiveExerciseItem
    let onOpenCard: () -> Void
    let onRemove: () -> Void

    var body: some View {
        return HStack(alignment: .top, spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(exercise.name)
                    .appStyle(Typography.title)
                    .foregroundStyle(Palette.textPrimary)
                Text(exercise.summary)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.xs)
            menu
        }
        .textCase(nil)
    }

    private var menu: some View {
        return Menu {
            Button(String(localized: "workout.exercise.card"), systemImage: "chart.line.uptrend.xyaxis", action: onOpenCard)
            Button(String(localized: "workout.exercise.remove"), systemImage: "minus.circle", role: .destructive, action: onRemove)
        } label: {
            return Image(systemName: Self.menuIconName)
                .appStyle(Typography.headline)
                .foregroundStyle(Palette.textSecondary)
                .frame(width: Self.menuTapSize, height: Self.menuTapSize)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(String(localized: "workout.exercise.menu \(exercise.name)"))
    }
}
