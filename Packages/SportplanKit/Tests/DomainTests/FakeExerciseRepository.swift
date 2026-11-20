import Domain
import Foundation
import Synchronization

final class FakeExerciseRepository: ExerciseRepository {
    private struct State {
        var library: [LibraryExercise] = []
        var created: [Exercise] = []
        var archivedIds: [UUID] = []
        var programDayCounts: [UUID: Int] = [:]
        var updated: [Exercise] = []
        var exerciseIdsWithCompletedSets: Set<UUID> = []
        var archived: [ArchivedExercise] = []
        var restoredIds: [UUID] = []
    }

    private let state = Mutex(State())

    init(
        library: [LibraryExercise] = [],
        programDayCounts: [UUID: Int] = [:],
        exerciseIdsWithCompletedSets: Set<UUID> = [],
        archived: [ArchivedExercise] = []
    ) {
        state.withLock { state in
            state.archived = archived
            state.library = library
            state.programDayCounts = programDayCounts
            state.exerciseIdsWithCompletedSets = exerciseIdsWithCompletedSets
        }
    }

    var restoredIds: [UUID] {
        return state.withLock { state in
            return state.restoredIds
        }
    }

    var updated: [Exercise] {
        return state.withLock { state in
            return state.updated
        }
    }

    var created: [Exercise] {
        return state.withLock { state in
            return state.created
        }
    }

    var archivedIds: [UUID] {
        return state.withLock { state in
            return state.archivedIds
        }
    }

    func observeLibrary() -> AsyncThrowingStream<[LibraryExercise], any Error> {
        let library = state.withLock { state in
            return state.library
        }
        return AsyncThrowingStream { continuation in
            continuation.yield(library)
            continuation.finish()
        }
    }

    func observeArchived() -> AsyncThrowingStream<[ArchivedExercise], any Error> {
        let archived = state.withLock { state in
            return state.archived
        }
        return AsyncThrowingStream { continuation in
            continuation.yield(archived)
            continuation.finish()
        }
    }

    func restore(id: UUID) async throws {
        state.withLock { state in
            state.restoredIds.append(id)
        }
    }

    func exercise(id: UUID) async throws -> Exercise? {
        return state.withLock { state in
            let stored = state.updated.reversed() + state.library.map { item in
                return item.exercise
            } + state.created
            return stored.first { exercise in
                return exercise.id == id
            }
        }
    }

    func create(_ exercise: Exercise) async throws {
        state.withLock { state in
            state.created.append(exercise)
        }
    }

    func update(_ exercise: Exercise) async throws {
        state.withLock { state in
            state.updated.append(exercise)
        }
    }

    func hasCompletedSets(exerciseId: UUID) async throws -> Bool {
        return state.withLock { state in
            return state.exerciseIdsWithCompletedSets.contains(exerciseId)
        }
    }

    func programDayCount(usingExerciseId id: UUID) async throws -> Int {
        return state.withLock { state in
            return state.programDayCounts[id, default: 0]
        }
    }

    func archive(id: UUID) async throws {
        state.withLock { state in
            state.archivedIds.append(id)
        }
    }
}
