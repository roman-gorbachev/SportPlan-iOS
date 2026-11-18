public struct ObserveProgramsUseCase: Sendable {
    private let repository: any ProgramRepository

    public init(repository: any ProgramRepository) {
        self.repository = repository
    }

    public func execute() -> AsyncThrowingStream<[ProgramSummary], any Error> {
        return repository.observePrograms()
    }
}
