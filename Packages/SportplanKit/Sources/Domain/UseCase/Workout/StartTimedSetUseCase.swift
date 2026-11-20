import Foundation

public struct StartTimedSetUseCase: Sendable {
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

    public func execute(setId: UUID) async throws {
        let active = try await repository.requiredActiveWorkout()
        guard let item = active.exercise(containingSetId: setId), let entry = item.set(id: setId) else {
            throw WorkoutError.notFound
        }
        guard item.exercise.metric == .duration, entry.state == .planned else {
            throw WorkoutError.invalidSet
        }
        var started = entry
        started.startedAt = now()
        try await repository.updateSet(started)
        if active.workout.rest != nil {
            try await repository.updateRest(workoutId: active.id, rest: nil)
            await scheduler.cancel()
        }
        guard let endsAt = started.targetEndsAt else {
            return
        }
        await scheduler.scheduleSetEnd(SetEndNotificationRequest(
            endsAt: endsAt,
            exerciseName: item.exercise.exercise.name,
            setNumber: item.number(of: started)
        ))
    }
}
