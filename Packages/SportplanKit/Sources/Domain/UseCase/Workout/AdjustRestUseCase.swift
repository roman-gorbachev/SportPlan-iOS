import Foundation

public struct AdjustRestUseCase: Sendable {
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

    public func execute(seconds: Int) async throws {
        let active = try await repository.requiredActiveWorkout()
        let date = now()
        guard let rest = active.workout.rest, rest.isActive(at: date) else {
            return
        }
        guard let adjusted = rest.adjusted(bySeconds: seconds, now: date) else {
            try await repository.updateRest(workoutId: active.id, rest: nil)
            await scheduler.cancel()
            return
        }
        try await repository.updateRest(workoutId: active.id, rest: adjusted)
        let next = active.restTrigger.flatMap { trigger in
            return active.nextPlannedSet(after: trigger)
        }
        await scheduler.schedule(RestNotificationRequest(
            endsAt: adjusted.endsAt,
            exerciseName: next?.exercise.exercise.exercise.name,
            setNumber: next?.number
        ))
    }
}
