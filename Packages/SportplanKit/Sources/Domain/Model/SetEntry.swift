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

extension SetEntry {
    public var state: SetEntryState {
        if completedAt != nil {
            return .completed
        }
        if startedAt != nil {
            return .running
        }
        return .planned
    }

    public var isCompleted: Bool {
        return completedAt != nil
    }

    public var targetEndsAt: Date? {
        guard state == .running, let startedAt, let durationSeconds, durationSeconds > .zero else {
            return nil
        }
        return startedAt.addingTimeInterval(TimeInterval(durationSeconds))
    }
}
