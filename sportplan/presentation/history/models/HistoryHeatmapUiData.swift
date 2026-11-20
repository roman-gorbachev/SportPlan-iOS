import DesignSystem
import Foundation

struct HistoryHeatmapUiData: Hashable {
    let title: String
    let summary: String
    let columns: [HeatmapColumn]
    let weekdayLabels: [String]
    let accessibilityLabel: String
}
