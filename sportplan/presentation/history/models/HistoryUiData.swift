import Foundation

struct HistoryUiData: Hashable {
    let heatmap: HistoryHeatmapUiData
    let sections: [HistoryMonthSection]

    var isEmpty: Bool {
        return sections.isEmpty
    }
}
