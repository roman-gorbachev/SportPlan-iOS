import Domain
import Foundation
import Testing

struct LoadWorkoutPreviewUseCaseTests {
    private static let targetSets = 3
    private static let bottomReps = 8
    private static let topReps = 12
    private static let targetReps = RepRange(min: bottomReps, max: topReps)
    private static let restSeconds = 120
    private static let secondsPerDay: TimeInterval = 86_400
    private static let longBreakDays = 12
    private static let shortBreakDays = 3

    private static func makeDetail(_ exercises: [LibraryExercise], startWeight: Weight? = nil) -> ProgramDayDetail {
        let day = ProgramDay(id: UUID(), programId: UUID(), name: "Грудь", label: "A", position: 0)
        let items = exercises.enumerated().map { position, exercise in
            return PlannedExerciseItem(
                plannedExercise: PlannedExercise(
                    id: UUID(),
                    programDayId: day.id,
                    exerciseId: exercise.id,
                    position: position,
                    targetSets: targetSets,
                    targetReps: exercise.exercise.metric == .weightReps ? targetReps : nil,
                    restSeconds: restSeconds,
                    startWeight: startWeight
                ),
                exercise: exercise
            )
        }
        return ProgramDayDetail(day: day, programName: "Сила", exercises: items)
    }

    private static func previousTargets(for exercise: LibraryExercise) -> WorkoutExercise {
        return WorkoutExercise(
            id: UUID(),
            workoutId: UUID(),
            exerciseId: exercise.id,
            position: 0,
            targetSets: targetSets,
            targetReps: targetReps,
            restSeconds: restSeconds
        )
    }

    private static func previousSets(kilograms: Double, reps: Int) -> [SetEntry] {
        return (0..<targetSets).map { position in
            return DomainFixtures.makeSet(position: position, kilograms: kilograms, reps: reps)
        }
    }

    private static func useCase(
        detail: ProgramDayDetail,
        workouts: FakeWorkoutRepository
    ) -> LoadWorkoutPreviewUseCase {
        return LoadWorkoutPreviewUseCase(
            workoutRepository: workouts,
            programRepository: FakeProgramRepository(dayDetails: [detail]),
            now: TestClock().now
        )
    }

    @Test func firstWorkoutUsesTheProgramStartWeight() async throws {
        let bench = DomainFixtures.makeLibraryExercise()
        let detail = Self.makeDetail([bench], startWeight: Weight(kilograms: 40))
        let preview = try await Self.useCase(detail: detail, workouts: FakeWorkoutRepository(library: [bench]))
            .execute(dayId: detail.day.id)

        #expect(preview.exercises.count == 1)
        #expect(preview.exercises[0].plannedSets.map(\.weight) == Array(repeating: Weight(kilograms: 40), count: Self.targetSets))
        #expect(preview.exercises[0].hasHistory == false)
        #expect(preview.lastWorkoutAt == nil)
        #expect(preview.tip == .firstWorkout)
    }

    @Test func completedTopOfRangeSuggestsTheNextWeight() async throws {
        let bench = DomainFixtures.makeLibraryExercise()
        let equipment = try #require(bench.equipment)
        let detail = Self.makeDetail([bench])
        let workouts = FakeWorkoutRepository(
            library: [bench],
            previousSets: [bench.id: Self.previousSets(kilograms: 60, reps: Self.topReps)],
            previousWorkoutExercises: [bench.id: Self.previousTargets(for: bench)],
            lastWorkoutDates: [detail.day.id: DomainFixtures.referenceDate]
        )
        let preview = try await Self.useCase(detail: detail, workouts: workouts).execute(dayId: detail.day.id)

        let suggested = Weight(kilograms: 60) + equipment.weightStep
        #expect(preview.exercises[0].progressionWeight == suggested)
        #expect(preview.tip == WorkoutPreviewTip.progression(exerciseName: bench.exercise.name, weight: suggested))
    }

    @Test func longBreakIsMentionedWhenNothingElseApplies() async throws {
        let bench = DomainFixtures.makeLibraryExercise()
        let detail = Self.makeDetail([bench])
        let lastWorkout = DomainFixtures.referenceDate.addingTimeInterval(-Self.secondsPerDay * TimeInterval(Self.longBreakDays))
        let workouts = FakeWorkoutRepository(
            library: [bench],
            previousSets: [bench.id: Self.previousSets(kilograms: 60, reps: Self.bottomReps)],
            previousWorkoutExercises: [bench.id: Self.previousTargets(for: bench)],
            lastWorkoutDates: [detail.day.id: lastWorkout]
        )
        let preview = try await Self.useCase(detail: detail, workouts: workouts).execute(dayId: detail.day.id)

        #expect(preview.exercises[0].progressionWeight == nil)
        #expect(preview.exercises[0].plannedSets.map(\.weight) == Array(repeating: Weight(kilograms: 60), count: Self.targetSets))
        #expect(preview.tip == WorkoutPreviewTip.longBreak(days: Self.longBreakDays))
    }

    @Test func recentWorkoutWithoutProgressionHasNoTip() async throws {
        let bench = DomainFixtures.makeLibraryExercise()
        let detail = Self.makeDetail([bench])
        let lastWorkout = DomainFixtures.referenceDate.addingTimeInterval(-Self.secondsPerDay * TimeInterval(Self.shortBreakDays))
        let workouts = FakeWorkoutRepository(
            library: [bench],
            previousSets: [bench.id: Self.previousSets(kilograms: 60, reps: Self.bottomReps)],
            previousWorkoutExercises: [bench.id: Self.previousTargets(for: bench)],
            lastWorkoutDates: [detail.day.id: lastWorkout]
        )
        let preview = try await Self.useCase(detail: detail, workouts: workouts).execute(dayId: detail.day.id)

        #expect(preview.lastWorkoutAt == lastWorkout)
        #expect(preview.tip == nil)
    }

    @Test func missingDayFails() async throws {
        let detail = Self.makeDetail([])
        await #expect(throws: WorkoutError.notFound) {
            try await Self.useCase(detail: detail, workouts: FakeWorkoutRepository()).execute(dayId: UUID())
        }
    }
}
