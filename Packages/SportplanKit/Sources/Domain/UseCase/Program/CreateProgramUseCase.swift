import Foundation

public struct CreateProgramUseCase: Sendable {
    private let repository: any ProgramRepository
    private let now: @Sendable () -> Date

    public init(repository: any ProgramRepository, now: @escaping @Sendable () -> Date) {
        self.repository = repository
        self.now = now
    }

    public func execute(program draft: ProgramDraft, firstDay dayDraft: ProgramDayDraft) async throws -> Program {
        let issues = draft.validationIssues.union(dayDraft.validationIssues)
        guard issues.isEmpty else {
            throw ProgramError.invalidDraft(issues)
        }
        let program = Program(id: UUID(), name: draft.trimmedName, position: 0, createdAt: now())
        let day = ProgramDay(
            id: UUID(),
            programId: program.id,
            name: dayDraft.trimmedName,
            label: dayDraft.trimmedLabel,
            position: 0
        )
        return try await repository.createProgram(program, firstDay: day)
    }
}
