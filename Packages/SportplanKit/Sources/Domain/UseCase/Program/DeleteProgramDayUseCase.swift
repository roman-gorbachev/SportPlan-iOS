import Foundation

public struct DeleteProgramDayUseCase: Sendable {
    private let repository: any ProgramRepository

    public init(repository: any ProgramRepository) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws {
        try await repository.deleteDay(id: id)
    }
}
