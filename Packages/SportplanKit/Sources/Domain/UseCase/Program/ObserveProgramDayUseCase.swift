import Foundation

public struct ObserveProgramDayUseCase: Sendable {
    private let repository: any ProgramRepository

    public init(repository: any ProgramRepository) {
        self.repository = repository
    }

    public func execute(id: UUID) -> AsyncThrowingStream<ProgramDayDetail?, any Error> {
        return repository.observeDay(id: id)
    }
}
