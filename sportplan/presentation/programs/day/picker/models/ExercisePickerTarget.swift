import Foundation

struct ExercisePickerTarget: Hashable, Identifiable {
    let destination: ExercisePickerDestination

    var id: ExercisePickerDestination {
        return destination
    }

    var dayContext: AddExerciseDayContext? {
        guard case let .day(id, _, fullTitle) = destination else {
            return nil
        }
        return AddExerciseDayContext(dayId: id, title: fullTitle)
    }
}
