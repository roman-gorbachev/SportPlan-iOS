import Foundation

public struct FinishedWorkoutDetail: Hashable, Sendable {
    public let workout: FinishedWorkout
    public let recordSetIds: Set<UUID>

    public init(workout: FinishedWorkout, recordSetIds: Set<UUID>) {
        self.workout = workout
        self.recordSetIds = recordSetIds
    }

    public var recordCount: Int {
        return workout.recordCount(in: recordSetIds)
    }
}
