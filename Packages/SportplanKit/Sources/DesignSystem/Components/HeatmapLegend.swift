import SwiftUI

public struct HeatmapLegend: View {
    private static let swatchSize: CGFloat = 14
    private static let swatchSpacing: CGFloat = 6

    private let lowLabel: String
    private let highLabel: String

    public init(lowLabel: String, highLabel: String) {
        self.lowLabel = lowLabel
        self.highLabel = highLabel
    }

    public var body: some View {
        return HStack(spacing: Self.swatchSpacing) {
            Text(lowLabel)
            ForEach(Palette.heatmapLevels.indices, id: \.self) { level in
                return RoundedRectangle(cornerRadius: CornerRadius.chip)
                    .fill(HeatmapPalette.color(level: level))
                    .frame(width: Self.swatchSize, height: Self.swatchSize)
            }
            Text(highLabel)
        }
        .appStyle(Typography.caption)
        .foregroundStyle(Palette.textSecondary)
        .accessibilityHidden(true)
    }
}
