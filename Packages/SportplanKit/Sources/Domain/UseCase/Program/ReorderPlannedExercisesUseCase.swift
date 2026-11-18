import Foundation

public struct ReorderPlannedExercisesUseCase: Sendable {
    private let repository: any ProgramRepository

    public init(repository: any ProgramRepository) {
        self.repository = repository
    }

    public func execute(dayId: UUID, orderedIds: [UUID]) async throws {
        try await repository.reorderPlannedExercises(dayId: dayId, orderedIds: orderedIds)
    }
}
