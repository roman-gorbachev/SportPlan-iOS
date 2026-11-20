import Foundation

public struct FinishedWorkout: Identifiable, Hashable, Sendable {
    public let workout: Workout
    public let programName: String?
    public let exercises: [FinishedWorkoutExercise]

    public init(workout: Workout, programName: String?, exercises: [FinishedWorkoutExercise]) {
        self.workout = workout
        self.programName = programName
        self.exercises = exercises
    }

    public var id: UUID {
        return workout.id
    }

    public var startedAt: Date {
        return workout.startedAt
    }

    public var finishedAt: Date {
        return workout.finishedAt ?? workout.startedAt
    }

    public var durationSeconds: Int {
        return max(Int(finishedAt.timeIntervalSince(startedAt)), .zero)
    }

    public var workingSetCount: Int {
        return exercises.reduce(.zero) { total, item in
            return total + item.workingSets.count
        }
    }

    public func recordCount(in recordSetIds: Set<UUID>) -> Int {
        return exercises.reduce(.zero) { total, item in
            return total + item.sets.filter { entry in
                return recordSetIds.contains(entry.id)
            }.count
        }
    }
}
