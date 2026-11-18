import SwiftUI

public struct InkButtonStyle: ButtonStyle {
    private static let minimumHeight: CGFloat = 48
    private static let pressedOpacity = 0.7
    private static let restingOpacity = 1.0

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        return configuration.label
            .appStyle(Typography.headline)
            .foregroundStyle(Palette.onInk)
            .padding(.horizontal, Spacing.xl)
            .frame(minHeight: Self.minimumHeight)
            .background(Palette.ink, in: Capsule())
            .opacity(configuration.isPressed ? Self.pressedOpacity : Self.restingOpacity)
    }
}
