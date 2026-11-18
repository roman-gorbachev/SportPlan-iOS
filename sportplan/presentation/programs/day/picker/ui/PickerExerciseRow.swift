import DesignSystem
import SwiftUI

struct PickerExerciseRow: View {
    let item: PickerExerciseItem
    let action: () -> Void

    var body: some View {
        return Button(action: action) {
            return HStack(spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(item.name)
                        .appStyle(Typography.body)
                        .foregroundStyle(item.isInDay ? Palette.textSecondary : Palette.textPrimary)
                    Text(item.detail)
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer(minLength: Spacing.s)
                if item.isInDay {
                    Label(String(localized: "picker.inDay"), systemImage: "checkmark")
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
        .disabled(item.isInDay)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.isInDay ? String(localized: "picker.inDay.accessibility \(item.name)") : String(localized: "picker.add.accessibility \(item.name)"))
        .accessibilityAddTraits(.isButton)
    }
}
