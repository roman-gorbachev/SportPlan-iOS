import DesignSystem
import SwiftUI

struct AddExerciseEquipmentRow: View {
    private static let checkmarkIconName = "checkmark"

    let item: AddExerciseEquipmentItem
    let action: () -> Void

    var body: some View {
        return Button(action: action) {
            return HStack(spacing: Spacing.s) {
                Text(item.name)
                    .appStyle(Typography.body)
                    .foregroundStyle(Palette.textPrimary)
                Spacer(minLength: Spacing.s)
                Text(item.weightsText)
                    .appStyle(Typography.numeralS)
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityLabel(item.weightsAccessibilityText)
                Image(systemName: Self.checkmarkIconName)
                    .appStyle(Typography.headline)
                    .foregroundStyle(Palette.accent)
                    .opacity(item.isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(item.isSelected ? [.isSelected] : [])
    }
}
