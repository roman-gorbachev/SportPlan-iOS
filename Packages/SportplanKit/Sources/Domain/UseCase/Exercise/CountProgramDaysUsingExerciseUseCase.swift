import Foundation

public struct CountProgramDaysUsingExerciseUseCase: Sendable {
    private let repository: any ExerciseRepository

    public init(repository: any ExerciseRepository) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws -> Int {
        return try await repository.programDayCount(usingExerciseId: id)
    }
}
