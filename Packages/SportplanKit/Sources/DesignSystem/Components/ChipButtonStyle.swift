import SwiftUI

public struct ChipButtonStyle: ButtonStyle {
    private static let minimumHeight: CGFloat = 44
    private static let pressedOpacity = 0.7
    private static let restingOpacity = 1.0
    private static let iconName = "plus"

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        return HStack(spacing: Spacing.xs) {
            Image(systemName: Self.iconName)
                .foregroundStyle(Palette.accent)
                .accessibilityHidden(true)
            configuration.label
                .foregroundStyle(Palette.textPrimary)
        }
        .appStyle(Typography.callout)
        .padding(.leading, Spacing.s)
        .padding(.trailing, Spacing.m)
        .frame(minHeight: Self.minimumHeight)
        .background(Palette.surface, in: Capsule())
        .contentShape(Capsule())
        .opacity(configuration.isPressed ? Self.pressedOpacity : Self.restingOpacity)
    }
}
