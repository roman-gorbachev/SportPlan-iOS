import Foundation

public struct HistoryEntry: Identifiable, Hashable, Sendable {
    public let workout: FinishedWorkout
    public let recordCount: Int

    public init(workout: FinishedWorkout, recordCount: Int) {
        self.workout = workout
        self.recordCount = recordCount
    }

    public var id: UUID {
        return workout.id
    }
}
