import Foundation

public struct StartTimedSetUseCase: Sendable {
    private let repository: any WorkoutRepository
    private let now: @Sendable () -> Date

    public init(repository: any WorkoutRepository, now: @escaping @Sendable () -> Date) {
        self.repository = repository
        self.now = now
    }

    public func execute(setId: UUID) async throws {
        let (item, entry) = try await repository.requiredSet(id: setId)
        guard item.exercise.metric == .duration, entry.state == .planned else {
            throw WorkoutError.invalidSet
        }
        var started = entry
        started.startedAt = now()
        try await repository.updateSet(started)
    }
}
