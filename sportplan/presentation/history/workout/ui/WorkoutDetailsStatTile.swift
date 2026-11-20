import DesignSystem
import SwiftUI

struct WorkoutDetailsStatTile: View {
    let title: String
    let value: String
    let unit: String?
    let isHighlighted: Bool

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .appStyle(Typography.caption)
                .foregroundStyle(isHighlighted ? Palette.onRecord : Palette.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                Text(value)
                    .appStyle(Typography.numeralM)
                    .foregroundStyle(isHighlighted ? Palette.onRecord : Palette.textPrimary)
                if let unit {
                    Text(unit)
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHighlighted ? Palette.record : Palette.surface, in: RoundedRectangle(cornerRadius: CornerRadius.field))
        .accessibilityElement(children: .combine)
    }
}
