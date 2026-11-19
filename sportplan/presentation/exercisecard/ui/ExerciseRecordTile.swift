import DesignSystem
import SwiftUI

struct ExerciseRecordTile: View {
    let item: ExerciseCardRecordItem

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(item.title)
                .appStyle(Typography.caption)
                .foregroundStyle(Palette.textSecondary)
            Text(item.value)
                .appStyle(Typography.numeralS)
                .foregroundStyle(Palette.textPrimary)
            Text(item.caption)
                .appStyle(Typography.caption)
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: CornerRadius.field))
        .accessibilityElement(children: .combine)
    }
}
