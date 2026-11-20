import Foundation

public struct ObserveArchivedExercisesUseCase: Sendable {
    private let repository: any ExerciseRepository

    public init(repository: any ExerciseRepository) {
        self.repository = repository
    }

    public func execute() -> AsyncThrowingStream<[ArchivedExercise], any Error> {
        return repository.observeArchived().mapElements { exercises in
            return exercises.sorted { lhs, rhs in
                return lhs.exercise.exercise.name.localizedStandardCompare(rhs.exercise.exercise.name) == .orderedAscending
            }
        }
    }
}
