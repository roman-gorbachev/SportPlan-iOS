import Foundation

public struct ArchiveExerciseUseCase: Sendable {
    private let repository: any ExerciseRepository

    public init(repository: any ExerciseRepository) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws {
        try await repository.archive(id: id)
    }
}
