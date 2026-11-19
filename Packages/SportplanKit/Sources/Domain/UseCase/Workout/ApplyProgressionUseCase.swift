import Foundation

public struct ApplyProgressionUseCase: Sendable {
    private let repository: any WorkoutRepository

    public init(repository: any WorkoutRepository) {
        self.repository = repository
    }

    public func execute(workoutExerciseId: UUID) async throws {
        let active = try await repository.requiredActiveWorkout()
        guard let item = active.exercise(id: workoutExerciseId) else {
            throw WorkoutError.notFound
        }
        guard let weight = item.progressionWeight else {
            return
        }
        let updated = item.pendingWorkingSets.map { entry in
            var changed = entry
            changed.weight = weight
            return changed
        }
        try await repository.updateSets(updated)
    }
}
