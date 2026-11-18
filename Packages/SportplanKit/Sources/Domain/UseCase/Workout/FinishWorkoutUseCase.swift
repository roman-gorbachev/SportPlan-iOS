import Foundation

public struct FinishWorkoutUseCase: Sendable {
    private let repository: any WorkoutRepository
    private let now: @Sendable () -> Date

    public init(repository: any WorkoutRepository, now: @escaping @Sendable () -> Date) {
        self.repository = repository
        self.now = now
    }

    public func execute() async throws {
        let active = try await repository.requiredActiveWorkout()
        guard active.hasCompletedSets else {
            try await repository.cancel(workoutId: active.id)
            return
        }
        try await repository.finish(workoutId: active.id, at: now())
    }
}
