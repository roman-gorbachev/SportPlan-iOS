import Foundation

struct ActiveExerciseItem: Identifiable {
    let id: UUID
    let name: String
    let summary: String
    let progression: ProgressionHintItem?
    let sets: [SetRowItem]
    let restTimer: RestTimerItem?
}
