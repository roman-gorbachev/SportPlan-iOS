import Foundation

public struct ActiveWorkout: Identifiable, Hashable, Sendable {
    public let workout: Workout
    public let programName: String?
    public let exercises: [ActiveWorkoutExercise]

    public init(workout: Workout, programName: String?, exercises: [ActiveWorkoutExercise]) {
        self.workout = workout
        self.programName = programName
        self.exercises = exercises
    }

    public var id: Workout.ID {
        return workout.id
    }

    public var exerciseIds: Set<UUID> {
        return Set(exercises.map { item in
            return item.exercise.id
        })
    }

    public var incompleteSetCount: Int {
        return exercises.reduce(0) { total, item in
            return total + item.sets.filter { entry in
                return !entry.isCompleted
            }.count
        }
    }

    public var hasCompletedSets: Bool {
        return exercises.contains { item in
            return item.sets.contains { entry in
                return entry.isCompleted
            }
        }
    }

    public func exercise(id: UUID) -> ActiveWorkoutExercise? {
        return exercises.first { item in
            return item.id == id
        }
    }

    public func exercise(containingSetId setId: UUID) -> ActiveWorkoutExercise? {
        return exercises.first { item in
            return item.set(id: setId) != nil
        }
    }

    public var restTrigger: WorkoutSetReference? {
        let completed = exercises.flatMap { item in
            return item.sets.compactMap { entry -> (WorkoutSetReference, Date)? in
                guard let completedAt = entry.completedAt else {
                    return nil
                }
                return (WorkoutSetReference(exercise: item, entry: entry), completedAt)
            }
        }
        return completed.max { lhs, rhs in
            return lhs.1 < rhs.1
        }?.0
    }

    public var currentSet: WorkoutSetReference? {
        if let trigger = restTrigger {
            return nextPlannedSet(after: trigger)
        }
        for item in exercises {
            if let entry = item.firstIncompleteSet {
                return WorkoutSetReference(exercise: item, entry: entry)
            }
        }
        return nil
    }

    public func nextPlannedSet(after reference: WorkoutSetReference) -> WorkoutSetReference? {
        guard let index = exercises.firstIndex(where: { item in return item.id == reference.exercise.id }) else {
            return nil
        }
        let ordered = exercises[index...] + exercises[..<index]
        for item in ordered {
            if let entry = item.firstIncompleteSet {
                return WorkoutSetReference(exercise: item, entry: entry)
            }
        }
        return nil
    }
}
