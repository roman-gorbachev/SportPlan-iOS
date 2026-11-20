import DesignSystem
import Foundation
import SwiftUI

struct HistoryHeatmapCard: View {
    private static let largestDynamicTypeSize = DynamicTypeSize.xxxLarge

    let data: HistoryHeatmapUiData
    let onSelectDay: (Date) -> Void

    var body: some View {
        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(data.title)
                    .appStyle(Typography.headline)
                    .foregroundStyle(Palette.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Spacing.xs)
                Text(data.summary)
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.trailing)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HeatmapGrid(
                    columns: data.columns,
                    weekdayLabels: data.weekdayLabels,
                    accessibilityLabel: data.accessibilityLabel,
                    onSelect: onSelectDay
                )
                HeatmapLegend(
                    lowLabel: String(localized: "history.heatmap.legend.low"),
                    highLabel: String(localized: "history.heatmap.legend.high")
                )
            }
            .dynamicTypeSize(...Self.largestDynamicTypeSize)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}
