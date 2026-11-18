import Foundation

public struct RemoveSetUseCase: Sendable {
    private let repository: any WorkoutRepository

    public init(repository: any WorkoutRepository) {
        self.repository = repository
    }

    public func execute(setId: UUID) async throws {
        try await repository.removeSet(id: setId)
    }
}
