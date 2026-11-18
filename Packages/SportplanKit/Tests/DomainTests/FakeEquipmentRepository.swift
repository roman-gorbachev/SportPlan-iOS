import Domain
import Foundation
import Synchronization

final class FakeEquipmentRepository: EquipmentRepository {
    private struct State {
        var equipment: [UUID: Equipment] = [:]
        var exerciseCounts: [UUID: Int] = [:]
    }

    private let state = Mutex(State())

    init(equipment: [Equipment] = [], exerciseCounts: [UUID: Int] = [:]) {
        state.withLock { state in
            for item in equipment {
                state.equipment[item.id] = item
            }
            state.exerciseCounts = exerciseCounts
        }
    }

    var stored: [Equipment] {
        return state.withLock { state in
            return Array(state.equipment.values)
        }
    }

    func observeActive() -> AsyncThrowingStream<[Equipment], any Error> {
        let active = stored.filter { item in
            return !item.isArchived
        }
        return AsyncThrowingStream { continuation in
            continuation.yield(active)
            continuation.finish()
        }
    }

    func equipment(id: UUID) async throws -> Equipment? {
        return state.withLock { state in
            return state.equipment[id]
        }
    }

    func save(_ equipment: Equipment) async throws {
        state.withLock { state in
            state.equipment[equipment.id] = equipment
        }
    }

    func archive(id: UUID) async throws {
        state.withLock { state in
            state.equipment[id]?.isArchived = true
        }
    }

    func exerciseCount(usingEquipmentId id: UUID) async throws -> Int {
        return state.withLock { state in
            return state.exerciseCounts[id, default: 0]
        }
    }
}
