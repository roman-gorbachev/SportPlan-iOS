import Foundation

public enum ExerciseLoad: Hashable, Sendable {
    case bodyweight
    case equipment(id: UUID)
}
