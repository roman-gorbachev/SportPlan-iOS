import Foundation

public struct RemoveSetUseCase: Sendable {
    private let repository: any WorkoutRepository
    private let scheduler: any RestNotificationScheduler

    public init(repository: any WorkoutRepository, scheduler: any RestNotificationScheduler) {
        self.repository = repository
        self.scheduler = scheduler
    }

    public func execute(setId: UUID) async throws {
        let (_, entry) = try await repository.requiredSet(id: setId)
        try await repository.removeSet(id: setId)
        if entry.state == .running {
            await scheduler.cancelSetEnd()
        }
    }
}
