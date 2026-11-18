import Foundation

public struct StartEmptyWorkoutUseCase: Sendable {
    private let repository: any WorkoutRepository
    private let now: @Sendable () -> Date

    public init(repository: any WorkoutRepository, now: @escaping @Sendable () -> Date) {
        self.repository = repository
        self.now = now
    }

    public func execute() async throws {
        guard try await repository.activeWorkout() == nil else {
            throw WorkoutError.alreadyActive
        }
        let workout = Workout(id: UUID(), programDay: nil, startedAt: now(), finishedAt: nil, note: nil, rest: nil)
        try await repository.start(workout, exercises: [], sets: [])
    }
}
