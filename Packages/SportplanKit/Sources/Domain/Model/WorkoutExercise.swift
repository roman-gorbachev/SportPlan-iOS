import Foundation

public struct WorkoutExercise: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let workoutId: UUID
    public let exerciseId: UUID
    public var position: Int
    public let targetSets: Int?
    public let targetReps: RepRange?
    public var restSeconds: Int
    public let targetDurationSeconds: Int?

    public init(
        id: UUID,
        workoutId: UUID,
        exerciseId: UUID,
        position: Int,
        targetSets: Int?,
        targetReps: RepRange?,
        restSeconds: Int,
        targetDurationSeconds: Int? = nil
    ) {
        self.id = id
        self.workoutId = workoutId
        self.exerciseId = exerciseId
        self.position = position
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.restSeconds = restSeconds
        self.targetDurationSeconds = targetDurationSeconds
    }
}
