public struct ObserveExerciseLibraryUseCase: Sendable {
    private let repository: any ExerciseRepository

    public init(repository: any ExerciseRepository) {
        self.repository = repository
    }

    public func execute() -> AsyncThrowingStream<ExerciseLibrary, any Error> {
        return repository.observeLibrary().mapElements { exercises in
            return ExerciseLibrary(exercises: exercises)
        }
    }
}
