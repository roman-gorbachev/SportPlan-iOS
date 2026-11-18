import Foundation

public struct UpdateProgramDayUseCase: Sendable {
    private let repository: any ProgramRepository

    public init(repository: any ProgramRepository) {
        self.repository = repository
    }

    public func execute(id: UUID, draft: ProgramDayDraft) async throws {
        let issues = draft.validationIssues
        guard issues.isEmpty else {
            throw ProgramError.invalidDraft(issues)
        }
        try await repository.updateDay(id: id, name: draft.trimmedName, label: draft.trimmedLabel)
    }
}
