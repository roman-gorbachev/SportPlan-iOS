import Foundation

public protocol EquipmentRepository: Sendable {
    func observeActive() -> AsyncThrowingStream<[Equipment], any Error>
    func equipment(id: UUID) async throws -> Equipment?
    func save(_ equipment: Equipment) async throws
    func archive(id: UUID) async throws
    func exerciseCount(usingEquipmentId id: UUID) async throws -> Int
}
