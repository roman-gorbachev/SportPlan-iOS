import Foundation

public struct FinishWorkoutUseCase: Sendable {
    private let repository: any WorkoutRepository
    private let scheduler: any RestNotificationScheduler
    private let now: @Sendable () -> Date

    public init(
        repository: any WorkoutRepository,
        scheduler: any RestNotificationScheduler,
        now: @escaping @Sendable () -> Date
    ) {
        self.repository = repository
        self.scheduler = scheduler
        self.now = now
    }

    public func execute() async throws {
        let active = try await repository.requiredActiveWorkout()
        guard active.hasCompletedSets else {
            try await repository.cancel(workoutId: active.id)
            await scheduler.cancel()
            await scheduler.cancelSetEnd()
            return
        }
        try await repository.finish(workoutId: active.id, at: now())
        await scheduler.cancel()
        await scheduler.cancelSetEnd()
    }
}
