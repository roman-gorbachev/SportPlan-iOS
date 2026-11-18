import Domain
import Foundation

extension ExerciseCategory {
    var libraryTitle: String {
        switch self {
        case .freeWeight:
            return String(localized: "library.section.freeWeight")
        case .machine:
            return String(localized: "library.section.machine")
        case .bodyweight:
            return String(localized: "library.section.bodyweight")
        }
    }

    var loadKindGroupTitle: String {
        switch self {
        case .freeWeight:
            return String(localized: "addExercise.group.freeWeight")
        case .machine:
            return String(localized: "addExercise.group.machine")
        case .bodyweight:
            return String(localized: "addExercise.group.bodyweight")
        }
    }
}
