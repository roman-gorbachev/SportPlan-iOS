import SwiftUI

public struct SunkenButtonStyle: ButtonStyle {
    private static let minimumHeight: CGFloat = 48
    private static let pressedOpacity = 0.7
    private static let restingOpacity = 1.0
    private static let disabledOpacity = 0.4

    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        return configuration.label
            .appStyle(Typography.callout)
            .foregroundStyle(Palette.textPrimary)
            .padding(.horizontal, Spacing.s)
            .frame(minHeight: Self.minimumHeight)
            .background(Palette.surfaceSunken, in: Capsule())
            .contentShape(Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? Self.pressedOpacity : Self.restingOpacity) : Self.disabledOpacity)
    }
}
