import Foundation

struct PickerExerciseItem: Identifiable {
    let id: UUID
    let name: String
    let detail: String
    let isAdded: Bool
    let accessibilityLabel: String
}
