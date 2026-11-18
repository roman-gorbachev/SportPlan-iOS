import SwiftUI

public struct ValueStepper: View {
    private static let buttonSize: CGFloat = 44
    private static let decrementIconName = "minus"
    private static let incrementIconName = "plus"

    private let title: String
    private let value: String
    private let accessibilityValueText: String
    private let canDecrement: Bool
    private let canIncrement: Bool
    private let onDecrement: () -> Void
    private let onIncrement: () -> Void

    public init(
        title: String,
        value: String,
        accessibilityValue: String,
        canDecrement: Bool,
        canIncrement: Bool,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) {
        self.title = title
        self.value = value
        self.accessibilityValueText = accessibilityValue
        self.canDecrement = canDecrement
        self.canIncrement = canIncrement
        self.onDecrement = onDecrement
        self.onIncrement = onIncrement
    }

    public var body: some View {
        return HStack(spacing: 0) {
            Text(title)
                .appStyle(Typography.callout)
                .foregroundStyle(Palette.textSecondary)
                .padding(.leading, Spacing.m)
            Spacer(minLength: Spacing.xs)
            stepButton(iconName: Self.decrementIconName, isEnabled: canDecrement, action: onDecrement)
            Text(value)
                .appStyle(Typography.numeralS)
                .foregroundStyle(Palette.textPrimary)
            stepButton(iconName: Self.incrementIconName, isEnabled: canIncrement, action: onIncrement)
        }
        .frame(minHeight: Self.buttonSize)
        .background(Palette.surface, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValueText)
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

    private func stepButton(iconName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        return Button(action: action) {
            return Image(systemName: iconName)
                .appStyle(Typography.headline)
                .foregroundStyle(isEnabled ? Palette.accent : Palette.textTertiary)
                .frame(width: Self.buttonSize, height: Self.buttonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
