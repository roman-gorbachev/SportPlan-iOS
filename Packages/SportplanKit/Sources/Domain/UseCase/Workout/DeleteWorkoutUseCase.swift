import Foundation

public struct DeleteWorkoutUseCase: Sendable {
    private let repository: any WorkoutRepository

    public init(repository: any WorkoutRepository) {
        self.repository = repository
    }

    public func execute(workoutId: UUID) async throws {
        try await repository.deleteFinished(workoutId: workoutId)
    }
}
