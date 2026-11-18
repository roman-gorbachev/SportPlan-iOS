import Foundation

public struct SetEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let workoutExerciseId: UUID
    public var position: Int
    public var weight: Weight
    public var reps: Int?
    public var durationSeconds: Int?
    public var isWarmup: Bool
    public var startedAt: Date?
    public var completedAt: Date?

    public init(
        id: UUID,
        workoutExerciseId: UUID,
        position: Int,
        weight: Weight,
        reps: Int?,
        durationSeconds: Int?,
        isWarmup: Bool,
        startedAt: Date?,
        completedAt: Date?
    ) {
        self.id = id
        self.workoutExerciseId = workoutExerciseId
        self.position = position
        self.weight = weight
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.isWarmup = isWarmup
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}
