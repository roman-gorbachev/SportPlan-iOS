import Foundation

public struct DeleteProgramUseCase: Sendable {
    private let repository: any ProgramRepository

    public init(repository: any ProgramRepository) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws {
        try await repository.deleteProgram(id: id)
    }
}
