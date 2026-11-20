import Foundation

struct HistoryDayUiData: Hashable {
    let title: String
    let items: [HistoryWorkoutItem]

    var isEmpty: Bool {
        return items.isEmpty
    }
}
