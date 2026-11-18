import Foundation

public struct CreateExerciseUseCase: Sendable {
    private let exerciseRepository: any ExerciseRepository
    private let equipmentRepository: any EquipmentRepository
    private let now: @Sendable () -> Date

    public init(
        exerciseRepository: any ExerciseRepository,
        equipmentRepository: any EquipmentRepository,
        now: @escaping @Sendable () -> Date
    ) {
        self.exerciseRepository = exerciseRepository
        self.equipmentRepository = equipmentRepository
        self.now = now
    }

    public func execute(draft: ExerciseDraft) async throws -> Exercise {
        let issues = draft.validationIssues
        guard issues.isEmpty, let load = draft.load else {
            throw ExerciseError.invalidDraft(issues)
        }
        if case let .equipment(id) = load {
            let equipment = try await equipmentRepository.equipment(id: id)
            guard let equipment, !equipment.isArchived, equipment.kind == draft.loadKind.equipmentKind else {
                throw ExerciseError.equipmentUnavailable
            }
        }
        let exercise = Exercise(
            id: UUID(),
            name: draft.trimmedName,
            description: draft.trimmedDescription,
            load: load,
            metric: draft.metric,
            restSeconds: draft.restSeconds,
            isArchived: false,
            createdAt: now()
        )
        try await exerciseRepository.create(exercise)
        return exercise
    }
}
