import Foundation

struct ActiveExerciseItem: Identifiable {
    let id: UUID
    let name: String
    let summary: String
    let sets: [SetRowItem]
}
