import DesignSystem
import SwiftUI

struct ProgressionHintView: View {
    private static let minimumTapSize: CGFloat = 44

    let hint: ProgressionHintItem
    let onApply: () -> Void
    let onDismiss: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xxs))
            : AnyLayout(HStackLayout(spacing: Spacing.xxs))
        return layout {
            message
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: Spacing.xxs) {
                applyButton
                dismissButton
            }
        }
        .padding(.leading, Spacing.s)
        .padding(.trailing, Spacing.xxs)
        .padding(.vertical, Spacing.xxs)
        .background(Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: CornerRadius.field))
    }

    private var message: some View {
        var weight = AttributedString(hint.weightText)
        weight.font = Typography.headline.font
        var text = AttributedString(hint.message)
        text.append(AttributedString(" "))
        text.append(weight)
        return Text(text)
            .appStyle(Typography.body)
            .foregroundStyle(Palette.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(hint.accessibilityLabel)
    }

    private var applyButton: some View {
        return Button(action: onApply) {
            return Text(String(localized: "workout.progression.apply"))
                .appStyle(Typography.headline)
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, Spacing.xs)
                .frame(minHeight: Self.minimumTapSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }

    private var dismissButton: some View {
        return Button(action: onDismiss) {
            return Image(systemName: "xmark")
                .appStyle(Typography.callout)
                .fontWeight(.semibold)
                .foregroundStyle(Palette.textSecondary)
                .frame(minWidth: Self.minimumTapSize, minHeight: Self.minimumTapSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(String(localized: "workout.progression.dismiss"))
    }
}

#Preview {
    FontRegistry.registerFonts()
    return ProgressionHintView(
        hint: ProgressionHintItem(
            message: "В прошлый раз всё выполнено — попробуй",
            weightText: "67,5 кг",
            accessibilityLabel: "В прошлый раз всё выполнено, попробуй 67,5 кг"
        ),
        onApply: {},
        onDismiss: {}
    )
    .padding(Spacing.m)
    .background(Palette.surface)
}
