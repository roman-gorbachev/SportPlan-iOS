import Foundation

struct ExercisePickerTarget: Hashable, Identifiable {
    let dayId: UUID
    let shortTitle: String
    let fullTitle: String

    var id: UUID {
        return dayId
    }
}
