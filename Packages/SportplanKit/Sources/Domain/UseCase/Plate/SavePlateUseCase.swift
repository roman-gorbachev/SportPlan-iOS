import Foundation

public struct SavePlateUseCase: Sendable {
    private let repository: any PlateRepository
    private let loadEditor: LoadPlateEditorUseCase

    public init(repository: any PlateRepository) {
        self.repository = repository
        self.loadEditor = LoadPlateEditorUseCase(repository: repository)
    }

    public func execute(draft: PlateDraft, existingId: UUID?) async throws -> Plate {
        let snapshot = try await loadEditor.execute(id: existingId)
        let issues = draft.validationIssues(takenWeights: snapshot.takenWeights)
        guard issues.isEmpty else {
            throw PlateError.invalidDraft(issues)
        }
        let plate = Plate(id: existingId ?? UUID(), weight: draft.weight, color: draft.color)
        try await repository.save(plate)
        return plate
    }
}
