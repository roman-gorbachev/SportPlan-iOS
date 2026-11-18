import Foundation

public struct RenameProgramUseCase: Sendable {
    private let repository: any ProgramRepository

    public init(repository: any ProgramRepository) {
        self.repository = repository
    }

    public func execute(id: UUID, draft: ProgramDraft) async throws {
        let issues = draft.validationIssues
        guard issues.isEmpty else {
            throw ProgramError.invalidDraft(issues)
        }
        try await repository.renameProgram(id: id, name: draft.trimmedName)
    }
}
