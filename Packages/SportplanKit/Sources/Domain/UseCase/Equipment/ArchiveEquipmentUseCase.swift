import Foundation

public struct ArchiveEquipmentUseCase: Sendable {
    private let repository: any EquipmentRepository

    public init(repository: any EquipmentRepository) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws {
        try await repository.archive(id: id)
    }
}
