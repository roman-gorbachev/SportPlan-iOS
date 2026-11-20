import Foundation

struct HistoryWorkoutItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let meta: String
    let recordCount: Int
    let recordCountText: String
    let accessibilityLabel: String
}
