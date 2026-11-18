import SwiftUI

public struct LargeValueStepper: View {
    private static let buttonSize: CGFloat = 56
    private static let wellPadding: CGFloat = 6
    private static let minimumValueScale: CGFloat = 0.6
    private static let decrementIconName = "minus"
    private static let incrementIconName = "plus"

    private let title: String
    private let caption: String
    private let value: String
    private let decrementLabel: String
    private let incrementLabel: String
    private let canDecrement: Bool
    private let canIncrement: Bool
    private let onDecrement: () -> Void
    private let onIncrement: () -> Void

    public init(
        title: String,
        caption: String,
        value: String,
        decrementLabel: String,
        incrementLabel: String,
        canDecrement: Bool,
        canIncrement: Bool,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) {
        self.title = title
        self.caption = caption
        self.value = value
        self.decrementLabel = decrementLabel
        self.incrementLabel = incrementLabel
        self.canDecrement = canDecrement
        self.canIncrement = canIncrement
        self.onDecrement = onDecrement
        self.onIncrement = onIncrement
    }

    public var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(title)
                Spacer(minLength: Spacing.xs)
                Text(caption)
            }
            .appStyle(Typography.footnote)
            .foregroundStyle(Palette.textSecondary)
            .accessibilityHidden(true)
            HStack(spacing: Spacing.xs) {
                stepButton(iconName: Self.decrementIconName, label: decrementLabel, isEnabled: canDecrement, action: onDecrement)
                Text(value)
                    .appStyle(Typography.numeralL)
                    .foregroundStyle(Palette.textPrimary)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(Self.minimumValueScale)
                stepButton(iconName: Self.incrementIconName, label: incrementLabel, isEnabled: canIncrement, action: onIncrement)
            }
            .padding(Self.wellPadding)
            .background(Palette.surfaceSunken, in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(value)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    if canIncrement {
                        onIncrement()
                    }
                case .decrement:
                    if canDecrement {
                        onDecrement()
                    }
                @unknown default:
                    break
                }
            }
        }
    }

    private func stepButton(iconName: String, label: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        return Button(action: action) {
            return Image(systemName: iconName)
                .appStyle(Typography.title)
                .foregroundStyle(isEnabled ? Palette.textPrimary : Palette.textTertiary)
                .frame(width: Self.buttonSize, height: Self.buttonSize)
                .background(Palette.surface, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

#Preview {
    FontRegistry.registerFonts()
    return VStack(spacing: Spacing.m) {
        LargeValueStepper(
            title: "Вес, кг",
            caption: "шаг 2,5 · олимпийский гриф",
            value: "65",
            decrementLabel: "Уменьшить вес на 2,5 кг",
            incrementLabel: "Увеличить вес на 2,5 кг",
            canDecrement: true,
            canIncrement: true,
            onDecrement: {},
            onIncrement: {}
        )
        LargeValueStepper(
            title: "Повторы",
            caption: "шаг 1",
            value: "0",
            decrementLabel: "Уменьшить повторы на 1",
            incrementLabel: "Увеличить повторы на 1",
            canDecrement: false,
            canIncrement: true,
            onDecrement: {},
            onIncrement: {}
        )
    }
    .padding()
    .background(Palette.surface)
}
