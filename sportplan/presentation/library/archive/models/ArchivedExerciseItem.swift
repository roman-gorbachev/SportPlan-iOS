import Foundation

struct ArchivedExerciseItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let detail: String
    let restoreAccessibilityLabel: String
}
