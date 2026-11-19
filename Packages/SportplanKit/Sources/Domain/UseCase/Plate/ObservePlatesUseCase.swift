public struct ObservePlatesUseCase: Sendable {
    private let repository: any PlateRepository

    public init(repository: any PlateRepository) {
        self.repository = repository
    }

    public func execute() -> AsyncThrowingStream<[Plate], any Error> {
        return repository.observeAll()
    }
}
