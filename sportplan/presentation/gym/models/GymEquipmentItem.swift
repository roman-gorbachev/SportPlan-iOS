import Foundation

struct GymEquipmentItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let kindTitle: String
    let weightsText: String
    let weightsAccessibilityText: String
}
