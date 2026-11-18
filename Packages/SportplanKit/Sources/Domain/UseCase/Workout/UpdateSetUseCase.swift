import Foundation

public struct UpdateSetUseCase: Sendable {
    private let repository: any WorkoutRepository

    public init(repository: any WorkoutRepository) {
        self.repository = repository
    }

    public func execute(setId: UUID, draft: SetEntryDraft) async throws {
        let (item, entry) = try await repository.requiredSet(id: setId)
        guard draft.isValid(for: item.exercise.metric) else {
            throw WorkoutError.invalidSet
        }
        try await repository.updateSet(draft.applied(to: entry))
    }
}
