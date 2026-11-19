import Foundation

struct SetRowItem: Identifiable {
    let id: UUID
    let number: Int
    let value: SetRowValue
    let valueAccessibility: String
    let isWarmup: Bool
    let isRecord: Bool
    let state: SetRowState
    let caption: String?
    let plates: SetRowPlates?
    let isTimed: Bool
    let isEditable: Bool
}
