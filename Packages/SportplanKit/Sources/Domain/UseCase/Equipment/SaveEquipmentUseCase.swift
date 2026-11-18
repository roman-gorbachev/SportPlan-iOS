import Foundation

public struct SaveEquipmentUseCase: Sendable {
    private let repository: any EquipmentRepository
    private let now: @Sendable () -> Date

    public init(repository: any EquipmentRepository, now: @escaping @Sendable () -> Date) {
        self.repository = repository
        self.now = now
    }

    public func execute(draft: EquipmentDraft, existingId: UUID?) async throws -> Equipment {
        let issues = draft.validationIssues
        guard issues.isEmpty else {
            throw EquipmentError.invalidDraft(issues)
        }
        let equipment: Equipment
        if let existingId {
            equipment = try await updated(existingId: existingId, draft: draft)
        } else {
            equipment = Equipment(
                id: UUID(),
                name: draft.trimmedName,
                kind: draft.kind,
                baseWeight: draft.effectiveBaseWeight,
                weightStep: draft.weightStep,
                isArchived: false,
                createdAt: now()
            )
        }
        try await repository.save(equipment)
        return equipment
    }

    private func updated(existingId: UUID, draft: EquipmentDraft) async throws -> Equipment {
        guard var equipment = try await repository.equipment(id: existingId) else {
            throw EquipmentError.notFound
        }
        if equipment.kind != draft.kind {
            let exerciseCount = try await repository.exerciseCount(usingEquipmentId: existingId)
            guard exerciseCount == 0 else {
                throw EquipmentError.kindLocked
            }
        }
        equipment.name = draft.trimmedName
        equipment.kind = draft.kind
        equipment.baseWeight = draft.effectiveBaseWeight
        equipment.weightStep = draft.weightStep
        return equipment
    }
}
