import Foundation

public struct AddSetUseCase: Sendable {
    private let repository: any WorkoutRepository

    public init(repository: any WorkoutRepository) {
        self.repository = repository
    }

    public func execute(workoutExerciseId: UUID, isWarmup: Bool) async throws {
        let active = try await repository.requiredActiveWorkout()
        guard let item = active.exercise(id: workoutExerciseId) else {
            throw WorkoutError.notFound
        }
        try await repository.addSet(WorkoutSetPlanner.newSet(in: item, isWarmup: isWarmup))
    }
}
