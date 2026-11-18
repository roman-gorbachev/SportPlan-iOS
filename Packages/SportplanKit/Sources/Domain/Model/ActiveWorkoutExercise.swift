import Foundation

public struct ActiveWorkoutExercise: Identifiable, Hashable, Sendable {
    private static let firstPosition = 0
    private static let firstSetNumber = 1

    public let workoutExercise: WorkoutExercise
    public let exercise: LibraryExercise
    public let sets: [SetEntry]
    public let previousSets: [SetEntry]

    public init(
        workoutExercise: WorkoutExercise,
        exercise: LibraryExercise,
        sets: [SetEntry],
        previousSets: [SetEntry]
    ) {
        self.workoutExercise = workoutExercise
        self.exercise = exercise
        self.sets = sets
        self.previousSets = previousSets
    }

    public var id: WorkoutExercise.ID {
        return workoutExercise.id
    }

    public var workingSets: [SetEntry] {
        return sets.filter { entry in
            return !entry.isWarmup
        }
    }

    public var completedWorkingSetCount: Int {
        return workingSets.filter { entry in
            return entry.isCompleted
        }.count
    }

    public var previousWorkingSets: [SetEntry] {
        return previousSets.filter { entry in
            return !entry.isWarmup
        }
    }

    public func set(id: UUID) -> SetEntry? {
        return sets.first { entry in
            return entry.id == id
        }
    }

    public var firstIncompleteSet: SetEntry? {
        return sets.first { entry in
            return !entry.isCompleted
        }
    }

    public func number(of entry: SetEntry) -> Int? {
        guard let index = sets.firstIndex(where: { candidate in return candidate.id == entry.id }) else {
            return nil
        }
        return index + Self.firstSetNumber
    }

    public func previousResult(for entry: SetEntry) -> SetEntry? {
        let sameKind = sets.filter { candidate in
            return candidate.isWarmup == entry.isWarmup
        }
        guard let index = sameKind.firstIndex(where: { candidate in return candidate.id == entry.id }) else {
            return nil
        }
        let previousSameKind = previousSets.filter { candidate in
            return candidate.isWarmup == entry.isWarmup
        }
        guard index < previousSameKind.count else {
            return nil
        }
        return previousSameKind[index]
    }

    public func setBefore(_ entry: SetEntry) -> SetEntry? {
        let sameKind = sets.filter { candidate in
            return candidate.isWarmup == entry.isWarmup
        }
        guard
            let index = sameKind.firstIndex(where: { candidate in return candidate.id == entry.id }),
            index > sameKind.startIndex
        else {
            return nil
        }
        return sameKind[sameKind.index(before: index)]
    }

    public func insertionPosition(isWarmup: Bool) -> Int {
        let nextPosition = sets.map(\.position).max().map { position in
            return position + 1
        } ?? Self.firstPosition
        guard isWarmup else {
            return nextPosition
        }
        guard let firstWorking = sets.first(where: { entry in return !entry.isWarmup }) else {
            return nextPosition
        }
        return firstWorking.position
    }
}
