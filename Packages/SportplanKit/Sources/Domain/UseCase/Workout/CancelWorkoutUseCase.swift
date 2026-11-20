public struct CancelWorkoutUseCase: Sendable {
    private let repository: any WorkoutRepository
    private let scheduler: any RestNotificationScheduler

    public init(repository: any WorkoutRepository, scheduler: any RestNotificationScheduler) {
        self.repository = repository
        self.scheduler = scheduler
    }

    public func execute() async throws {
        let active = try await repository.requiredActiveWorkout()
        try await repository.cancel(workoutId: active.id)
        await scheduler.cancel()
        await scheduler.cancelSetEnd()
    }
}
