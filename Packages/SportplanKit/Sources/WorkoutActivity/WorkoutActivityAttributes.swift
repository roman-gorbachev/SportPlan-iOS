import Foundation

public struct WorkoutActivityAttributes: Codable, Hashable, Sendable {
    public let workoutId: UUID
    public let startedAt: Date

    public init(workoutId: UUID, startedAt: Date) {
        self.workoutId = workoutId
        self.startedAt = startedAt
    }
}
