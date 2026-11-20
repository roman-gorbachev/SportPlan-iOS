import Foundation

public struct UpdateExerciseUseCase: Sendable {
    private let exerciseRepository: any ExerciseRepository
    private let equipmentRepository: any EquipmentRepository
    private let loadKindResolver: ExerciseLoadKindResolver

    public init(exerciseRepository: any ExerciseRepository, equipmentRepository: any EquipmentRepository) {
        self.exerciseRepository = exerciseRepository
        self.equipmentRepository = equipmentRepository
        self.loadKindResolver = ExerciseLoadKindResolver(equipmentRepository: equipmentRepository)
    }

    @discardableResult
    public func execute(exerciseId: UUID, draft: ExerciseDraft) async throws -> Exercise {
        guard let current = try await exerciseRepository.exercise(id: exerciseId) else {
            throw ExerciseError.notFound
        }
        guard try await loadKindResolver.loadKind(of: current) == draft.loadKind else {
            throw ExerciseError.loadKindChanged
        }
        let issues = draft.validationIssues
        guard issues.isEmpty, let load = draft.load else {
            throw ExerciseError.invalidDraft(issues)
        }
        if load != current.load, case let .equipment(id) = load {
            let equipment = try await equipmentRepository.equipment(id: id)
            guard let equipment, !equipment.isArchived, equipment.kind == draft.loadKind.equipmentKind else {
                throw ExerciseError.equipmentUnavailable
            }
        }
        if draft.metric != current.metric, try await exerciseRepository.hasCompletedSets(exerciseId: exerciseId) {
            throw ExerciseError.metricLocked
        }
        var updated = current
        updated.name = draft.trimmedName
        updated.description = draft.trimmedDescription
        updated.load = load
        updated.metric = draft.metric
        updated.restSeconds = draft.restSeconds
        try await exerciseRepository.update(updated)
        return updated
    }
}
