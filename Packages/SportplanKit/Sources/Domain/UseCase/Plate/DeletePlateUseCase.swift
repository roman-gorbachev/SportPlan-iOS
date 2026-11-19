import Foundation

public struct DeletePlateUseCase: Sendable {
    private let repository: any PlateRepository

    public init(repository: any PlateRepository) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
