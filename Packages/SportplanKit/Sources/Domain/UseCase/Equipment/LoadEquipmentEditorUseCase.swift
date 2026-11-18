import Foundation

public struct LoadEquipmentEditorUseCase: Sendable {
    private let repository: any EquipmentRepository

    public init(repository: any EquipmentRepository) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws -> EquipmentEditorSnapshot {
        guard let equipment = try await repository.equipment(id: id) else {
            throw EquipmentError.notFound
        }
        let exerciseCount = try await repository.exerciseCount(usingEquipmentId: id)
        return EquipmentEditorSnapshot(equipment: equipment, exerciseCount: exerciseCount)
    }
}
