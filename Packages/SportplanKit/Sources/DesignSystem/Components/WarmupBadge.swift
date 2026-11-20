import SwiftUI

public struct WarmupBadge: View {
    private static let horizontalPadding: CGFloat = 7
    private static let verticalPadding: CGFloat = 1
    private static let borderWidth: CGFloat = 1

    private let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        return Text(title)
            .appStyle(Typography.caption)
            .foregroundStyle(Palette.warmup)
            .padding(.horizontal, Self.horizontalPadding)
            .padding(.vertical, Self.verticalPadding)
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.chip)
                    .strokeBorder(Palette.separatorStrong, lineWidth: Self.borderWidth)
            }
    }
}
