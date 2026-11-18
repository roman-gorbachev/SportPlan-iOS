import Domain
import Foundation
import Synchronization

final class FakeExerciseRepository: ExerciseRepository {
    private struct State {
        var library: [LibraryExercise] = []
        var created: [Exercise] = []
        var archivedIds: [UUID] = []
        var programDayCounts: [UUID: Int] = [:]
    }

    private let state = Mutex(State())

    init(library: [LibraryExercise] = [], programDayCounts: [UUID: Int] = [:]) {
        state.withLock { state in
            state.library = library
            state.programDayCounts = programDayCounts
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

    func create(_ exercise: Exercise) async throws {
        state.withLock { state in
            state.created.append(exercise)
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
