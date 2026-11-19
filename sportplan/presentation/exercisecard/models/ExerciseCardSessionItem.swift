import Foundation

struct ExerciseCardSessionItem: Identifiable, Hashable {
    let id: UUID
    let date: String
    let sets: String
    let isRecord: Bool
    let accessibilityLabel: String
}
