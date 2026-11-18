import DesignSystem
import SwiftUI

struct PickerExerciseRow: View {
    let item: PickerExerciseItem
    let addedLabel: String
    let action: () -> Void

    var body: some View {
        return Button(action: action) {
            return HStack(spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(item.name)
                        .appStyle(Typography.body)
                        .foregroundStyle(item.isAdded ? Palette.textSecondary : Palette.textPrimary)
                    Text(item.detail)
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer(minLength: Spacing.s)
                if item.isAdded {
                    Label(addedLabel, systemImage: "checkmark")
                        .appStyle(Typography.callout)
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .appStyle(Typography.title)
                        .foregroundStyle(Palette.accent)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(item.isAdded)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }
}
