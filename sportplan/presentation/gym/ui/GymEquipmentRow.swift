import DesignSystem
import SwiftUI

struct GymEquipmentRow: View {
    let item: GymEquipmentItem
    let action: () -> Void

    var body: some View {
        return Button(action: action) {
            return HStack(spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(item.name)
                        .appStyle(Typography.body)
                        .foregroundStyle(Palette.textPrimary)
                    Text(item.kindTitle)
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer(minLength: Spacing.s)
                Text(item.weightsText)
                    .appStyle(Typography.numeralS)
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityLabel(item.weightsAccessibilityText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
