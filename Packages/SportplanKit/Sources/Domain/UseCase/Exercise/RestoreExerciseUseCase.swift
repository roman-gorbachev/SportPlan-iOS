import Foundation

public struct RestoreExerciseUseCase: Sendable {
    private let repository: any ExerciseRepository

    public init(repository: any ExerciseRepository) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws {
        try await repository.restore(id: id)
    }
}
