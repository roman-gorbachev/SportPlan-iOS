import Domain
import Foundation
import Testing

struct LoadEquipmentEditorUseCaseTests {
    @Test func locksKindWhenUsed() async throws {
        let equipment = Equipment(
            id: UUID(),
            name: "Смит",
            kind: .barbell,
            baseWeight: Weight(kilograms: 15),
            weightStep: Weight(kilograms: 2.5),
            isArchived: false,
            createdAt: Date(timeIntervalSince1970: 0)
        )
        let repository = FakeEquipmentRepository(equipment: [equipment], exerciseCounts: [equipment.id: 4])
        let snapshot = try await LoadEquipmentEditorUseCase(repository: repository).execute(id: equipment.id)
        #expect(snapshot.exerciseCount == 4)
        #expect(snapshot.isKindLocked)
    }

    @Test func failsForMissingEquipment() async {
        let repository = FakeEquipmentRepository()
        await #expect(throws: EquipmentError.notFound) {
            _ = try await LoadEquipmentEditorUseCase(repository: repository).execute(id: UUID())
        }
    }
}
