import Foundation

public struct ExerciseSession: Identifiable, Hashable, Sendable {
    public let workoutId: UUID
    public let date: Date
    public let sets: [SetEntry]

    public init(workoutId: UUID, date: Date, sets: [SetEntry]) {
        self.workoutId = workoutId
        self.date = date
        self.sets = sets
    }

    public var id: UUID {
        return workoutId
    }
}
