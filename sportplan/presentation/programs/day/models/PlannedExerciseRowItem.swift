import Foundation

struct PlannedExerciseRowItem: Identifiable {
    let id: UUID
    let name: String
    let targetText: String
    let targetAccessibilityText: String
    let detailText: String
}
