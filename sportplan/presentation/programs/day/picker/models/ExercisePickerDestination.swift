import Foundation

enum ExercisePickerDestination: Hashable {
    case day(id: UUID, shortTitle: String, fullTitle: String)
    case workout(id: UUID)
}
