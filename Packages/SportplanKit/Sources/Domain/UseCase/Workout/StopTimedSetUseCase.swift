import Foundation

public struct StopTimedSetUseCase: Sendable {
    private static let minimumDurationSeconds = 0

    private let repository: any WorkoutRepository
    private let now: @Sendable () -> Date

    public init(repository: any WorkoutRepository, now: @escaping @Sendable () -> Date) {
        self.repository = repository
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
    }
}
