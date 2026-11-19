import Foundation

struct ExerciseCardChartPoint: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let value: Double
    let label: String
    let selectionLabel: String
    let isRecord: Bool
    let isLast: Bool
}
