import Foundation

public protocol ExerciseRepository: Sendable {
    func observeLibrary() -> AsyncThrowingStream<[LibraryExercise], any Error>
    func observeArchived() -> AsyncThrowingStream<[ArchivedExercise], any Error>
    func exercise(id: UUID) async throws -> Exercise?
    func create(_ exercise: Exercise) async throws
    func update(_ exercise: Exercise) async throws
    func hasCompletedSets(exerciseId: UUID) async throws -> Bool
    func programDayCount(usingExerciseId id: UUID) async throws -> Int
    func archive(id: UUID) async throws
    func restore(id: UUID) async throws
}
