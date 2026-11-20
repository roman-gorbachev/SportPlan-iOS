import Foundation

struct ActiveExerciseItem: Identifiable {
    let id: UUID
    let exerciseId: UUID
    let name: String
    let summary: String
    let progression: ProgressionHintItem?
    let sets: [SetRowItem]
    let restTimer: RestTimerItem?
}
