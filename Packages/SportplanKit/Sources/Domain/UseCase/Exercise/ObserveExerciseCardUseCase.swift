import Foundation

public struct ObserveExerciseCardUseCase: Sendable {
    private let repository: any WorkoutRepository

    public init(repository: any WorkoutRepository) {
        self.repository = repository
    }

    public func execute(exerciseId: UUID) -> AsyncThrowingStream<ExerciseCard, any Error> {
        let source = repository.observeExerciseHistory(exerciseId: exerciseId)
        return AsyncThrowingStream<ExerciseCard, any Error> { continuation in
            let task = Task {
                do {
                    for try await history in source {
                        guard let history else {
                            throw ExerciseError.notFound
                        }
                        continuation.yield(ExerciseCard(history: history))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
