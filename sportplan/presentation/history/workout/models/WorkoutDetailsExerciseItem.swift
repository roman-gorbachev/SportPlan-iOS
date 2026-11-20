import Foundation

struct WorkoutDetailsExerciseItem: Identifiable, Hashable {
    let id: UUID
    let exerciseId: UUID
    let name: String
    let goal: String
    let sets: [WorkoutDetailsSetItem]
}
