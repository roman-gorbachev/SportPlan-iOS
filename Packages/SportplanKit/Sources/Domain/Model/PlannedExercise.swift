import Foundation

public struct PlannedExercise: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let programDayId: UUID
    public let exerciseId: UUID
    public var position: Int
    public var targetSets: Int
    public var targetReps: RepRange?
    public var restSeconds: Int

    public init(
        id: UUID,
        programDayId: UUID,
        exerciseId: UUID,
        position: Int,
        targetSets: Int,
        targetReps: RepRange?,
        restSeconds: Int
    ) {
        self.id = id
        self.programDayId = programDayId
        self.exerciseId = exerciseId
        self.position = position
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.restSeconds = restSeconds
    }

    public var targets: PlannedExerciseTargets {
        return PlannedExerciseTargets(sets: targetSets, reps: targetReps, restSeconds: restSeconds)
    }
}
