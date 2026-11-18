import Domain
import Foundation
import Testing

struct AddExerciseToDayUseCaseTests {
    private static func makeUseCase(
        programs: FakeProgramRepository,
        exercises: [Exercise]
    ) -> AddExerciseToDayUseCase {
        let library = exercises.map { exercise in
            return LibraryExercise(exercise: exercise, equipment: nil)
        }
        return AddExerciseToDayUseCase(
            programRepository: programs,
            exerciseRepository: FakeExerciseRepository(library: library)
        )
    }

    @Test func addsExerciseWithDefaultTargets() async throws {
        let exercise = DomainFixtures.makeExercise(name: "Брусья", load: .bodyweight)
        let programs = FakeProgramRepository()
        let dayId = UUID()
        let planned = try await Self.makeUseCase(programs: programs, exercises: [exercise]).execute(exerciseId: exercise.id, dayId: dayId)
        #expect(planned.programDayId == dayId)
        #expect(planned.exerciseId == exercise.id)
        #expect(planned.targets == PlannedExerciseTargets(defaultsFor: exercise))
        #expect(programs.plannedExercises == [planned])
    }

    @Test func addsExerciseWithGivenTargets() async throws {
        let exercise = DomainFixtures.makeExercise(name: "Планка", load: .bodyweight, metric: .duration)
        let programs = FakeProgramRepository()
        let targets = PlannedExerciseTargets(sets: 4, reps: nil, restSeconds: 60)
        let planned = try await Self.makeUseCase(programs: programs, exercises: [exercise]).execute(exerciseId: exercise.id, dayId: UUID(), targets: targets)
        #expect(planned.targets == targets)
    }

    @Test func rejectsArchivedOrMissingExercise() async throws {
        var archived = DomainFixtures.makeExercise(name: "Жим лёжа", load: .bodyweight)
        archived.isArchived = true
        let programs = FakeProgramRepository()
        let useCase = Self.makeUseCase(programs: programs, exercises: [archived])
        for exerciseId in [archived.id, UUID()] {
            await #expect(throws: ProgramError.exerciseUnavailable) {
                _ = try await useCase.execute(exerciseId: exerciseId, dayId: UUID())
            }
        }
        #expect(programs.plannedExercises.isEmpty)
    }

    @Test func rejectsTargetsThatDoNotMatchMetric() async throws {
        let exercise = DomainFixtures.makeExercise(name: "Планка", load: .bodyweight, metric: .duration)
        let programs = FakeProgramRepository()
        let targets = PlannedExerciseTargets(sets: 3, reps: RepRange(min: 8, max: 12), restSeconds: 60)
        await #expect(throws: ProgramError.invalidTargets([.repsNotAllowed])) {
            _ = try await Self.makeUseCase(programs: programs, exercises: [exercise]).execute(exerciseId: exercise.id, dayId: UUID(), targets: targets)
        }
        #expect(programs.plannedExercises.isEmpty)
    }
}
