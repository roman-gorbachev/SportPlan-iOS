import DesignSystem
import SwiftUI

struct GymPlateRow: View {
    private static let weightColumnWidth: CGFloat = 76

    let item: GymPlateItem
    let action: () -> Void

    @ScaledMetric(relativeTo: .headline) private var weightColumnWidth = Self.weightColumnWidth

    var body: some View {
        return Button(action: action) {
            return HStack(spacing: Spacing.s) {
                PlateGlyph(plate: item.plate)
                Text(item.weightText)
                    .appStyle(Typography.numeralS)
                    .foregroundStyle(Palette.textPrimary)
                    .frame(minWidth: weightColumnWidth, alignment: .leading)
                Text(item.colorText)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
                Spacer(minLength: Spacing.s)
                Image(systemName: "chevron.right")
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textTertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
