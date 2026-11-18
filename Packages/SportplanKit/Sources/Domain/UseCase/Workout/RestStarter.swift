import Foundation

struct RestStarter: Sendable {
    private static let minimumRestSeconds = 0

    private let repository: any WorkoutRepository
    private let scheduler: any RestNotificationScheduler
    private let now: @Sendable () -> Date

    init(
        repository: any WorkoutRepository,
        scheduler: any RestNotificationScheduler,
        now: @escaping @Sendable () -> Date
    ) {
        self.repository = repository
        self.scheduler = scheduler
        self.now = now
    }

    func startRest(afterSetId setId: UUID) async throws {
        let active = try await repository.requiredActiveWorkout()
        guard let item = active.exercise(containingSetId: setId), let entry = item.set(id: setId) else {
            throw WorkoutError.notFound
        }
        let seconds = item.workoutExercise.restSeconds
        guard seconds > Self.minimumRestSeconds else {
            try await repository.updateRest(workoutId: active.id, rest: nil)
            await scheduler.cancel()
            return
        }
        let rest = RestPeriod(startedAt: now(), seconds: seconds)
        try await repository.updateRest(workoutId: active.id, rest: rest)
        let next = active.nextPlannedSet(after: WorkoutSetReference(exercise: item, entry: entry))
        await scheduler.schedule(RestNotificationRequest(
            endsAt: rest.endsAt,
            exerciseName: next?.exercise.exercise.exercise.name,
            setNumber: next?.number
        ))
    }
}
