import Foundation

public struct UpdateWorkoutNoteUseCase: Sendable {
    private let repository: any WorkoutRepository

    public init(repository: any WorkoutRepository) {
        self.repository = repository
    }

    public func execute(workoutId: UUID, note: String) async throws {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        try await repository.updateNote(workoutId: workoutId, note: trimmed.isEmpty ? nil : trimmed)
    }
}
