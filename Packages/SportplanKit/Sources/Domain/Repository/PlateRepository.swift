import Foundation

public protocol PlateRepository: Sendable {
    func observeAll() -> AsyncThrowingStream<[Plate], any Error>
    func plates() async throws -> [Plate]
    func save(_ plate: Plate) async throws
    func delete(id: UUID) async throws
    func replaceAll(with plates: [Plate]) async throws
}
