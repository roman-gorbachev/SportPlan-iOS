import DesignSystem
import SwiftUI

struct ProgramDayLabelBadge: View {
    private static let baseSize: CGFloat = 28

    private let label: String
    @ScaledMetric(relativeTo: .headline) private var size = ProgramDayLabelBadge.baseSize

    init(label: String) {
        self.label = label
    }

    var body: some View {
        return Text(label)
            .appStyle(Typography.headline)
            .foregroundStyle(Palette.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, Spacing.xxs)
            .frame(minWidth: size, minHeight: size)
            .background(Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: CornerRadius.chip))
    }
}
