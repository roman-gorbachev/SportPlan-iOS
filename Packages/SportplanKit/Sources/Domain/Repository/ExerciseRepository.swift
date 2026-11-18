import Foundation

public protocol ExerciseRepository: Sendable {
    func observeLibrary() -> AsyncThrowingStream<[LibraryExercise], any Error>
    func exercise(id: UUID) async throws -> Exercise?
    func create(_ exercise: Exercise) async throws
    func programDayCount(usingExerciseId id: UUID) async throws -> Int
    func archive(id: UUID) async throws
}
