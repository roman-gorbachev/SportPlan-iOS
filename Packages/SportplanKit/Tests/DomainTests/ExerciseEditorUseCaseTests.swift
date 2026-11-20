import Domain
import Foundation
import Testing

struct ExerciseEditorUseCaseTests {
    private struct Setup {
        let bar: Equipment
        let ezBar: Equipment
        let dumbbells: Equipment
        let archivedBar: Equipment
        let bench: Exercise
        let plank: Exercise
        let exercises: FakeExerciseRepository
        let equipment: FakeEquipmentRepository
    }

    private static let programDayCount = 2

    private static func makeSetup(withCompletedSets: Bool = false) -> Setup {
        let bar = DomainFixtures.makeEquipment()
        let ezBar = DomainFixtures.makeEquipment(name: "EZ-гриф")
        let dumbbells = DomainFixtures.makeEquipment(name: "Гантели", kind: .dumbbell)
        let archivedBar = DomainFixtures.makeEquipment(name: "Старый гриф", isArchived: true)
        let bench = DomainFixtures.makeExercise(name: "Жим лёжа", load: .equipment(id: bar.id))
        let plank = DomainFixtures.makeExercise(name: "Планка", load: .bodyweight, metric: .duration)
        let library = [
            LibraryExercise(exercise: bench, equipment: bar),
            LibraryExercise(exercise: plank, equipment: nil),
        ]
        let exercises = FakeExerciseRepository(
            library: library,
            programDayCounts: [bench.id: programDayCount],
            exerciseIdsWithCompletedSets: withCompletedSets ? [bench.id, plank.id] : []
        )
        let equipment = FakeEquipmentRepository(equipment: [bar, ezBar, dumbbells, archivedBar])
        return Setup(
            bar: bar,
            ezBar: ezBar,
            dumbbells: dumbbells,
            archivedBar: archivedBar,
            bench: bench,
            plank: plank,
            exercises: exercises,
            equipment: equipment
        )
    }

    private static func makeUpdate(_ setup: Setup) -> UpdateExerciseUseCase {
        return UpdateExerciseUseCase(exerciseRepository: setup.exercises, equipmentRepository: setup.equipment)
    }

    @Test func loadsTheEditorSnapshot() async throws {
        let setup = Self.makeSetup(withCompletedSets: true)
        let useCase = LoadExerciseEditorUseCase(exerciseRepository: setup.exercises, equipmentRepository: setup.equipment)
        let snapshot = try await useCase.execute(exerciseId: setup.bench.id)
        #expect(snapshot.loadKind == .equipment(.barbell))
        #expect(snapshot.isMetricLocked)
        #expect(snapshot.programDayCount == Self.programDayCount)
        #expect(snapshot.draft.equipmentId == setup.bar.id)
        #expect(snapshot.draft.name == setup.bench.name)
    }

    @Test func updatesNameRestAndEquipmentOfTheSameKind() async throws {
        let setup = Self.makeSetup(withCompletedSets: true)
        var draft = ExerciseDraft(exercise: setup.bench, loadKind: .equipment(.barbell))
        draft.name = " Жим на скамье "
        draft.description = " Пауза на груди "
        draft.equipmentId = setup.ezBar.id
        draft.incrementRest()
        let updated = try await Self.makeUpdate(setup).execute(exerciseId: setup.bench.id, draft: draft)
        #expect(updated.name == "Жим на скамье")
        #expect(updated.description == "Пауза на груди")
        #expect(updated.load == .equipment(id: setup.ezBar.id))
        #expect(updated.restSeconds == Exercise.defaultRestSeconds + Exercise.restStepSeconds)
        #expect(updated.createdAt == setup.bench.createdAt)
        #expect(setup.exercises.updated == [updated])
    }

    @Test func rejectsAnotherLoadKind() async throws {
        let setup = Self.makeSetup()
        let draft = ExerciseDraft(name: "Жим", loadKind: .equipment(.dumbbell), equipmentId: setup.dumbbells.id)
        await #expect(throws: ExerciseError.loadKindChanged) {
            try await Self.makeUpdate(setup).execute(exerciseId: setup.bench.id, draft: draft)
        }
        #expect(setup.exercises.updated.isEmpty)
    }

    @Test func rejectsArchivedOrMissingEquipment() async throws {
        let setup = Self.makeSetup()
        for equipmentId in [setup.archivedBar.id, UUID()] {
            var draft = ExerciseDraft(exercise: setup.bench, loadKind: .equipment(.barbell))
            draft.equipmentId = equipmentId
            await #expect(throws: ExerciseError.equipmentUnavailable) {
                try await Self.makeUpdate(setup).execute(exerciseId: setup.bench.id, draft: draft)
            }
        }
        #expect(setup.exercises.updated.isEmpty)
    }

    @Test func locksTheMetricOnceSetsAreCompleted() async throws {
        let locked = Self.makeSetup(withCompletedSets: true)
        var draft = ExerciseDraft(exercise: locked.plank, loadKind: .bodyweight)
        draft.metric = .weightReps
        await #expect(throws: ExerciseError.metricLocked) {
            try await Self.makeUpdate(locked).execute(exerciseId: locked.plank.id, draft: draft)
        }
        let free = Self.makeSetup()
        let updated = try await Self.makeUpdate(free).execute(exerciseId: free.plank.id, draft: draft)
        #expect(updated.metric == .weightReps)
    }

    @Test func failsForAMissingExercise() async throws {
        let setup = Self.makeSetup()
        await #expect(throws: ExerciseError.notFound) {
            try await Self.makeUpdate(setup).execute(exerciseId: UUID(), draft: ExerciseDraft(name: "Жим", loadKind: .bodyweight))
        }
    }
}
