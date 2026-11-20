import Foundation

struct WorkoutDetailsSetItem: Identifiable, Hashable {
    let id: UUID
    let number: String
    let value: String
    let isWarmup: Bool
    let isRecord: Bool
    let accessibilityLabel: String
}
