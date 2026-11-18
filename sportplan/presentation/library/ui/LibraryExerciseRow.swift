import DesignSystem
import SwiftUI

struct LibraryExerciseRow: View {
    let item: LibraryExerciseItem

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(item.name)
                .appStyle(Typography.body)
                .foregroundStyle(Palette.textPrimary)
            Text(item.detail)
                .appStyle(Typography.footnote)
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
