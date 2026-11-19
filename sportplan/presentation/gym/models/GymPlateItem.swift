import DesignSystem
import Foundation

struct GymPlateItem: Identifiable, Hashable {
    let id: UUID
    let plate: PlateStackItem
    let weightText: String
    let colorText: String
}
