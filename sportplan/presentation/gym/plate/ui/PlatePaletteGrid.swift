import DesignSystem
import Domain
import SwiftUI

struct PlatePaletteGrid: View {
    private static let columnMinimumWidth: CGFloat = 72

    let selectedColor: PlateColor
    let onSelect: (PlateColor) -> Void
    let onPickCustom: () -> Void

    @ScaledMetric(relativeTo: .caption) private var columnMinimumWidth = Self.columnMinimumWidth

    var body: some View {
        let selectedPaletteColor = PlatePaletteColor(color: selectedColor)
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: columnMinimumWidth), spacing: Spacing.xs)], spacing: Spacing.m) {
            ForEach(PlatePaletteColor.allCases, id: \.self) { paletteColor in
                return swatchButton(
                    rgb: paletteColor.color.rgb,
                    title: paletteColor.title,
                    isSelected: paletteColor == selectedPaletteColor,
                    action: { onSelect(paletteColor.color) }
                )
            }
            swatchButton(
                rgb: selectedPaletteColor == nil ? selectedColor.rgb : nil,
                title: String(localized: "plate.color.custom"),
                isSelected: selectedPaletteColor == nil,
                action: onPickCustom
            )
        }
        .padding(.vertical, Spacing.m)
        .padding(.horizontal, Spacing.xs)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private func swatchButton(rgb: Int?, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        return Button(action: action) {
            return VStack(spacing: Spacing.xxs) {
                PlateSwatch(rgb: rgb, isSelected: isSelected)
                Text(title)
                    .appStyle(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}
