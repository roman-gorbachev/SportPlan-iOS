import Domain
import Foundation
import Testing

struct ApplyProgressionUseCaseTests {
    private struct Context {
        let repository: FakeWorkoutRepository
        let workoutExercise: WorkoutExercise
        let sets: [SetEntry]
    }

    private static func makeContext(previousReps: Int = 12) async throws -> Context {
        let bench = DomainFixtures.makeLibraryExercise()
        let previousTargets = WorkoutExercise(
            id: UUID(),
            workoutId: UUID(),
            exerciseId: bench.id,
            position: 0,
            targetSets: 2,
            targetReps: RepRange(min: 8, max: 12),
            restSeconds: Exercise.defaultRestSeconds
        )
        let previousSets = [
            DomainFixtures.makeSet(position: 0, kilograms: 60, reps: previousReps),
            DomainFixtures.makeSet(position: 1, kilograms: 60, reps: previousReps)
        ]
        let repository = FakeWorkoutRepository(
            library: [bench],
            previousSets: [bench.id: previousSets],
            previousWorkoutExercises: [bench.id: previousTargets]
        )
        let workout = Workout(
            id: UUID(),
            programDay: nil,
            startedAt: DomainFixtures.referenceDate,
            finishedAt: nil,
            note: nil,
            rest: nil
        )
        let workoutExercise = WorkoutExercise(
            id: UUID(),
            workoutId: workout.id,
            exerciseId: bench.id,
            position: 0,
            targetSets: 2,
            targetReps: RepRange(min: 8, max: 12),
            restSeconds: Exercise.defaultRestSeconds
        )
        let sets = [
            DomainFixtures.makeSet(workoutExerciseId: workoutExercise.id, position: 0, kilograms: 40, reps: 10, isWarmup: true, completedAt: nil),
            DomainFixtures.makeSet(workoutExerciseId: workoutExercise.id, position: 1, kilograms: 60, reps: 12),
            DomainFixtures.makeSet(workoutExerciseId: workoutExercise.id, position: 2, kilograms: 60, reps: 12, completedAt: nil),
            DomainFixtures.makeSet(workoutExerciseId: workoutExercise.id, position: 3, kilograms: 57.5, reps: 10, completedAt: nil)
        ]
        try await repository.start(workout, exercises: [workoutExercise], sets: sets)
        return Context(repository: repository, workoutExercise: workoutExercise, sets: sets)
    }

    @Test func appliesSuggestedWeightToPendingWorkingSetsOnly() async throws {
        let context = try await Self.makeContext()

        try await ApplyProgressionUseCase(repository: context.repository).execute(workoutExerciseId: context.workoutExercise.id)

        let stored = context.repository.sets
        #expect(stored.map(\.weight) == [40, 60, 62.5, 62.5].map { kilograms in return Weight(kilograms: kilograms) })
        #expect(stored.map(\.reps) == [10, 12, 12, 10])
        #expect(stored.map(\.isCompleted) == [false, true, false, false])
        #expect(context.repository.updateSetsCallCount == 1)
        let active = try #require(try await context.repository.activeWorkout())
        #expect(active.exercises[0].progressionWeight == nil)
    }

    @Test func doesNothingWithoutSuggestion() async throws {
        let context = try await Self.makeContext(previousReps: 11)

        try await ApplyProgressionUseCase(repository: context.repository).execute(workoutExerciseId: context.workoutExercise.id)

        #expect(context.repository.sets.map(\.weight) == context.sets.map(\.weight))
        #expect(context.repository.updateSetsCallCount == 0)
    }

    @Test func unknownExerciseIsRejected() async throws {
        let context = try await Self.makeContext()

        await #expect(throws: WorkoutError.notFound) {
            try await ApplyProgressionUseCase(repository: context.repository).execute(workoutExerciseId: UUID())
        }
    }
}
