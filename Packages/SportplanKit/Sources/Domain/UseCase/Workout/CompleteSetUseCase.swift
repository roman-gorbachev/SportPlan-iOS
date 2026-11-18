import Foundation

public struct CompleteSetUseCase: Sendable {
    private let repository: any WorkoutRepository
    private let restStarter: RestStarter
    private let now: @Sendable () -> Date

    public init(
        repository: any WorkoutRepository,
        scheduler: any RestNotificationScheduler,
        now: @escaping @Sendable () -> Date
    ) {
        self.repository = repository
        self.restStarter = RestStarter(repository: repository, scheduler: scheduler, now: now)
        self.now = now
    }

    public func execute(setId: UUID, draft: SetEntryDraft) async throws {
        let (item, entry) = try await repository.requiredSet(id: setId)
        guard draft.isValid(for: item.exercise.metric) else {
            throw WorkoutError.invalidSet
        }
        if item.exercise.metric == .duration, draft.durationSeconds == nil {
            throw WorkoutError.invalidSet
        }
        var completed = draft.applied(to: entry)
        completed.completedAt = entry.completedAt ?? now()
        try await repository.updateSet(completed)
        guard !entry.isCompleted else {
            return
        }
        try await restStarter.startRest(afterSetId: setId)
    }
}
