import Foundation

struct AddExerciseEquipmentItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let weightsText: String
    let weightsAccessibilityText: String
    let isSelected: Bool
}
