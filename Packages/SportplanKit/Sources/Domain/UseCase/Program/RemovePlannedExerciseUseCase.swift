import Foundation

public struct RemovePlannedExerciseUseCase: Sendable {
    private let repository: any ProgramRepository

    public init(repository: any ProgramRepository) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws {
        try await repository.removePlannedExercise(id: id)
    }
}
