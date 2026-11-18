import Domain
import Foundation
import Testing

struct CreateExerciseUseCaseTests {
    private static func makeUseCase(
        exercises: FakeExerciseRepository,
        equipment: FakeEquipmentRepository
    ) -> CreateExerciseUseCase {
        return CreateExerciseUseCase(
            exerciseRepository: exercises,
            equipmentRepository: equipment,
            now: { return DomainFixtures.referenceDate }
        )
    }

    @Test func createsExerciseWithEquipment() async throws {
        let bar = DomainFixtures.makeEquipment()
        let exercises = FakeExerciseRepository()
        let useCase = Self.makeUseCase(exercises: exercises, equipment: FakeEquipmentRepository(equipment: [bar]))
        let draft = ExerciseDraft(name: " Жим лёжа ", loadKind: .equipment(.barbell), equipmentId: bar.id, description: " ")
        let created = try await useCase.execute(draft: draft)
        #expect(created.name == "Жим лёжа")
        #expect(created.load == .equipment(id: bar.id))
        #expect(created.description == nil)
        #expect(created.createdAt == DomainFixtures.referenceDate)
        #expect(exercises.created == [created])
    }

    @Test func createsBodyweightExercise() async throws {
        let exercises = FakeExerciseRepository()
        let useCase = Self.makeUseCase(exercises: exercises, equipment: FakeEquipmentRepository())
        let created = try await useCase.execute(draft: ExerciseDraft(quickExercise: .plank, name: "Планка"))
        #expect(created.load == .bodyweight)
        #expect(created.metric == .duration)
    }

    @Test func rejectsInvalidDraft() async throws {
        let exercises = FakeExerciseRepository()
        let useCase = Self.makeUseCase(exercises: exercises, equipment: FakeEquipmentRepository())
        await #expect(throws: ExerciseError.invalidDraft([.missingEquipment])) {
            _ = try await useCase.execute(draft: ExerciseDraft(name: "Присед", loadKind: .equipment(.barbell)))
        }
        #expect(exercises.created.isEmpty)
    }

    @Test func rejectsArchivedMissingOrMismatchedEquipment() async throws {
        let archived = DomainFixtures.makeEquipment(isArchived: true)
        let dumbbells = DomainFixtures.makeEquipment(name: "Гантели", kind: .dumbbell)
        let exercises = FakeExerciseRepository()
        let useCase = Self.makeUseCase(exercises: exercises, equipment: FakeEquipmentRepository(equipment: [archived, dumbbells]))
        for equipmentId in [archived.id, dumbbells.id, UUID()] {
            let draft = ExerciseDraft(name: "Жим лёжа", loadKind: .equipment(.barbell), equipmentId: equipmentId)
            await #expect(throws: ExerciseError.equipmentUnavailable) {
                _ = try await useCase.execute(draft: draft)
            }
        }
        #expect(exercises.created.isEmpty)
    }
}
