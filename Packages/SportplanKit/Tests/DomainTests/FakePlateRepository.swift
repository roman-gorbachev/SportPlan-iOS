import Domain
import Foundation
import Synchronization

final class FakePlateRepository: PlateRepository {
    private let state: Mutex<[Plate]>

    init(plates: [Plate] = []) {
        state = Mutex(plates)
    }

    var stored: [Plate] {
        return state.withLock { plates in
            return plates
        }
    }

    func observeAll() -> AsyncThrowingStream<[Plate], any Error> {
        let plates = stored
        return AsyncThrowingStream { continuation in
            continuation.yield(plates)
            continuation.finish()
        }
    }

    func plates() async throws -> [Plate] {
        return stored
    }

    func save(_ plate: Plate) async throws {
        state.withLock { plates in
            if let index = plates.firstIndex(where: { candidate in
                return candidate.id == plate.id
            }) {
                plates[index] = plate
            } else {
                plates.append(plate)
            }
        }
    }

    func delete(id: UUID) async throws {
        state.withLock { plates in
            plates.removeAll { plate in
                return plate.id == id
            }
        }
    }

    func replaceAll(with plates: [Plate]) async throws {
        state.withLock { stored in
            stored = plates
        }
    }
}
