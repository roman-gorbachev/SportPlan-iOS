public struct CancelWorkoutUseCase: Sendable {
    private let repository: any WorkoutRepository

    public init(repository: any WorkoutRepository) {
        self.repository = repository
    }

    public func execute() async throws {
        let active = try await repository.requiredActiveWorkout()
        try await repository.cancel(workoutId: active.id)
    }
}
