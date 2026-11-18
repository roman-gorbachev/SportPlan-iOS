public struct ObserveActiveWorkoutUseCase: Sendable {
    private let repository: any WorkoutRepository

    public init(repository: any WorkoutRepository) {
        self.repository = repository
    }

    public func execute() -> AsyncThrowingStream<ActiveWorkout?, any Error> {
        return repository.observeActive()
    }
}
