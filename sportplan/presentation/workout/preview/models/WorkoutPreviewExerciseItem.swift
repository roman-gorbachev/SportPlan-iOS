import Foundation

struct WorkoutPreviewExerciseItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let plan: String
    let planAccessibility: String
}
