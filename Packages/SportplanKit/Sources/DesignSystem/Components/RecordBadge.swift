import SwiftUI

public struct RecordBadge: View {
    private static let horizontalPadding: CGFloat = 7
    private static let verticalPadding: CGFloat = 2
    private static let iconSpacing: CGFloat = 4

    private let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        return HStack(spacing: Self.iconSpacing) {
            Image(systemName: "arrow.up")
                .fontWeight(.bold)
                .imageScale(.small)
            Text(title)
        }
        .appStyle(Typography.caption)
        .foregroundStyle(Palette.onRecord)
        .padding(.horizontal, Self.horizontalPadding)
        .padding(.vertical, Self.verticalPadding)
        .background(Palette.record, in: RoundedRectangle(cornerRadius: CornerRadius.chip))
    }
}
