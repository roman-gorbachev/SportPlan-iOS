import Foundation

public struct AddProgramDayUseCase: Sendable {
    private let repository: any ProgramRepository

    public init(repository: any ProgramRepository) {
        self.repository = repository
    }

    public func execute(programId: UUID, draft: ProgramDayDraft) async throws -> ProgramDay {
        let issues = draft.validationIssues
        guard issues.isEmpty else {
            throw ProgramError.invalidDraft(issues)
        }
        let day = ProgramDay(
            id: UUID(),
            programId: programId,
            name: draft.trimmedName,
            label: draft.trimmedLabel,
            position: 0
        )
        return try await repository.addDay(day)
    }
}
