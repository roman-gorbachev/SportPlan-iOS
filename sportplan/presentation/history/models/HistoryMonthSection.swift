import Foundation

struct HistoryMonthSection: Identifiable, Hashable {
    let id: Date
    let title: String
    var items: [HistoryWorkoutItem]
}
