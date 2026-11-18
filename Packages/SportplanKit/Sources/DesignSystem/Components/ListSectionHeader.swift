import SwiftUI

public struct ListSectionHeader: View {
    private let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        return Text(title)
            .appStyle(Typography.footnote)
            .foregroundStyle(Palette.textSecondary)
    }
}
