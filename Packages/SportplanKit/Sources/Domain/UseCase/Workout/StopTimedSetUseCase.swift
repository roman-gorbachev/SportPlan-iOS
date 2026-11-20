import Foundation

public struct StopTimedSetUseCase: Sendable {
    private static let minimumDurationSeconds = 0

    private let repository: any WorkoutRepository
    private let scheduler: any RestNotificationScheduler
    private let restStarter: RestStarter
    private let now: @Sendable () -> Date

    public init(
        repository: any WorkoutRepository,
        scheduler: any RestNotificationScheduler,
        now: @escaping @Sendable () -> Date
    ) {
        self.repository = repository
        self.scheduler = scheduler
        self.restStarter = RestStarter(repository: repository, scheduler: scheduler, now: now)
        self.now = now
    }

    public func execute(setId: UUID) async throws {
        let (_, entry) = try await repository.requiredSet(id: setId)
        guard entry.state == .running, let startedAt = entry.startedAt else {
            throw WorkoutError.invalidSet
        }
        let stoppedAt = now()
        let elapsed = Int(stoppedAt.timeIntervalSince(startedAt).rounded())
        var stopped = entry
        stopped.durationSeconds = max(elapsed, Self.minimumDurationSeconds)
        stopped.completedAt = stoppedAt
        try await repository.updateSet(stopped)
        await scheduler.cancelSetEnd()
        try await restStarter.startRest(afterSetId: setId)
    }
}
