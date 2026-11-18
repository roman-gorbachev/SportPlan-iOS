import Domain
import Foundation
import Testing

struct UpdatePlannedExerciseTargetsUseCaseTests {
    private static func makePlanned(exerciseId: UUID) -> PlannedExercise {
        return PlannedExercise(
            id: UUID(),
            programDayId: UUID(),
            exerciseId: exerciseId,
            position: 0,
            targetSets: 3,
            targetReps: RepRange(min: 8, max: 12),
            restSeconds: Exercise.defaultRestSeconds
        )
    }

    @Test func updatesTargets() async throws {
        let exercise = DomainFixtures.makeExercise(name: "Жим лёжа", load: .bodyweight)
        let planned = Self.makePlanned(exerciseId: exercise.id)
        let programs = FakeProgramRepository(plannedExercises: [planned])
        let useCase = UpdatePlannedExerciseTargetsUseCase(
            programRepository: programs,
            exerciseRepository: FakeExerciseRepository(library: [LibraryExercise(exercise: exercise, equipment: nil)])
        )
        let targets = PlannedExerciseTargets(sets: 5, reps: RepRange(min: 5, max: 5), restSeconds: 180)
        try await useCase.execute(id: planned.id, targets: targets)
        #expect(programs.plannedExercises.first?.targets == targets)
    }

    @Test func rejectsMissingRepsForRepetitions() async throws {
        let exercise = DomainFixtures.makeExercise(name: "Жим лёжа", load: .bodyweight)
        let planned = Self.makePlanned(exerciseId: exercise.id)
        let programs = FakeProgramRepository(plannedExercises: [planned])
        let useCase = UpdatePlannedExerciseTargetsUseCase(
            programRepository: programs,
            exerciseRepository: FakeExerciseRepository(library: [LibraryExercise(exercise: exercise, equipment: nil)])
        )
        await #expect(throws: ProgramError.invalidTargets([.missingReps])) {
            try await useCase.execute(id: planned.id, targets: PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: 90))
        }
        #expect(programs.plannedExercises == [planned])
    }

    @Test func missingPlannedExerciseIsNotFound() async throws {
        let useCase = UpdatePlannedExerciseTargetsUseCase(
            programRepository: FakeProgramRepository(),
            exerciseRepository: FakeExerciseRepository()
        )
        await #expect(throws: ProgramError.notFound) {
            try await useCase.execute(id: UUID(), targets: PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: 90))
        }
    }
}
