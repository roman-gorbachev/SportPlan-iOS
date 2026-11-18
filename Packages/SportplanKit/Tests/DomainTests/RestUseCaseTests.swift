import Domain
import Foundation
import Testing

struct RestUseCaseTests {
    private struct Setup {
        let workouts: FakeWorkoutRepository
        let scheduler: FakeRestNotificationScheduler
        let clock: TestClock
        let benchSets: [SetEntry]
        let squatSets: [SetEntry]
    }

    private static func makeSetup(benchRestSeconds: Int = 120, benchMetric: ExerciseMetric = .weightReps) async throws -> Setup {
        let bench = DomainFixtures.makeLibraryExercise(metric: benchMetric)
        let squat = DomainFixtures.makeLibraryExercise(name: "Присед")
        let clock = TestClock()
        let workouts = FakeWorkoutRepository(library: [bench, squat])
        try await StartEmptyWorkoutUseCase(repository: workouts, now: clock.now).execute()
        let workoutId = try #require(try await workouts.activeWorkout()).id
        let benchItem = WorkoutExercise(id: UUID(), workoutId: workoutId, exerciseId: bench.id, position: 0, targetSets: nil, targetReps: nil, restSeconds: benchRestSeconds)
        let squatItem = WorkoutExercise(id: UUID(), workoutId: workoutId, exerciseId: squat.id, position: 1, targetSets: nil, targetReps: nil, restSeconds: 180)
        let benchSets = (0..<2).map { position in
            return DomainFixtures.makeSet(workoutExerciseId: benchItem.id, position: position, kilograms: 60, reps: 8, completedAt: nil)
        }
        let squatSets = [DomainFixtures.makeSet(workoutExerciseId: squatItem.id, position: 0, kilograms: 80, reps: 5, completedAt: nil)]
        try await workouts.addExercise(benchItem, sets: benchSets)
        try await workouts.addExercise(squatItem, sets: squatSets)
        return Setup(workouts: workouts, scheduler: FakeRestNotificationScheduler(), clock: clock, benchSets: benchSets, squatSets: squatSets)
    }

    private static func complete(_ entry: SetEntry, in setup: Setup) async throws {
        let draft = SetEntryDraft(weight: entry.weight, reps: entry.reps, durationSeconds: nil)
        try await CompleteSetUseCase(repository: setup.workouts, scheduler: setup.scheduler, now: setup.clock.now)
            .execute(setId: entry.id, draft: draft)
    }

    private static func rest(_ setup: Setup) -> RestPeriod? {
        return setup.workouts.workouts.first?.rest
    }

    @Test func completingASetStartsRestAndSchedulesTheNextSet() async throws {
        let setup = try await Self.makeSetup()
        setup.clock.advance(by: 10)
        try await Self.complete(setup.benchSets[0], in: setup)

        let start = DomainFixtures.referenceDate.addingTimeInterval(10)
        #expect(Self.rest(setup) == RestPeriod(startedAt: start, seconds: 120))
        #expect(setup.scheduler.scheduled == RestNotificationRequest(
            endsAt: start.addingTimeInterval(120),
            exerciseName: "Жим лёжа",
            setNumber: 2
        ))
    }

    @Test func lastSetOfAnExercisePointsToTheNextExercise() async throws {
        let setup = try await Self.makeSetup()
        try await Self.complete(setup.benchSets[0], in: setup)
        try await Self.complete(setup.benchSets[1], in: setup)
        #expect(setup.scheduler.scheduled?.exerciseName == "Присед")
        #expect(setup.scheduler.scheduled?.setNumber == 1)

        try await Self.complete(setup.squatSets[0], in: setup)
        #expect(setup.scheduler.scheduled?.exerciseName == nil)
        #expect(setup.scheduler.scheduled?.setNumber == nil)
        #expect(Self.rest(setup)?.duration == 180)
    }

    @Test func editingACompletedSetKeepsTheRest() async throws {
        let setup = try await Self.makeSetup()
        try await Self.complete(setup.benchSets[0], in: setup)
        let rest = Self.rest(setup)
        setup.clock.advance(by: 30)
        try await Self.complete(setup.benchSets[0], in: setup)
        #expect(Self.rest(setup) == rest)
    }

    @Test func newSetReplacesTheRunningRest() async throws {
        let setup = try await Self.makeSetup()
        try await Self.complete(setup.benchSets[0], in: setup)
        setup.clock.advance(by: 40)
        try await Self.complete(setup.benchSets[1], in: setup)
        #expect(Self.rest(setup)?.startedAt == DomainFixtures.referenceDate.addingTimeInterval(40))
    }

    @Test func zeroRestDoesNotStartATimer() async throws {
        let setup = try await Self.makeSetup(benchRestSeconds: 0)
        try await Self.complete(setup.benchSets[0], in: setup)
        #expect(Self.rest(setup) == nil)
        #expect(setup.scheduler.scheduled == nil)
    }

    @Test func stoppingTheStopwatchStartsRest() async throws {
        let setup = try await Self.makeSetup(benchMetric: .duration)
        let entry = setup.benchSets[0]
        try await StartTimedSetUseCase(repository: setup.workouts, now: setup.clock.now).execute(setId: entry.id)
        setup.clock.advance(by: 45)
        try await StopTimedSetUseCase(repository: setup.workouts, scheduler: setup.scheduler, now: setup.clock.now)
            .execute(setId: entry.id)
        #expect(Self.rest(setup)?.startedAt == DomainFixtures.referenceDate.addingTimeInterval(45))
        #expect(setup.scheduler.scheduled != nil)
    }

    @Test func adjustingMovesTheEndAndReschedules() async throws {
        let setup = try await Self.makeSetup()
        try await Self.complete(setup.benchSets[0], in: setup)
        let adjust = AdjustRestUseCase(repository: setup.workouts, scheduler: setup.scheduler, now: setup.clock.now)

        try await adjust.execute(seconds: RestPeriod.adjustmentStepSeconds)
        #expect(Self.rest(setup)?.duration == 135)
        #expect(setup.scheduler.scheduled?.endsAt == DomainFixtures.referenceDate.addingTimeInterval(135))
        #expect(setup.scheduler.scheduled?.setNumber == 2)

        setup.clock.advance(by: 125)
        try await adjust.execute(seconds: -RestPeriod.adjustmentStepSeconds)
        #expect(Self.rest(setup) == nil)
        #expect(setup.scheduler.scheduled == nil)
        #expect(setup.scheduler.cancelCount == 1)
    }

    @Test func adjustingAnEndedRestDoesNothing() async throws {
        let setup = try await Self.makeSetup()
        try await Self.complete(setup.benchSets[0], in: setup)
        let rest = Self.rest(setup)
        setup.clock.advance(by: 200)
        try await AdjustRestUseCase(repository: setup.workouts, scheduler: setup.scheduler, now: setup.clock.now)
            .execute(seconds: RestPeriod.adjustmentStepSeconds)
        #expect(Self.rest(setup) == rest)
    }

    @Test func skipClearsRestAndNotification() async throws {
        let setup = try await Self.makeSetup()
        try await Self.complete(setup.benchSets[0], in: setup)
        try await SkipRestUseCase(repository: setup.workouts, scheduler: setup.scheduler).execute()
        #expect(Self.rest(setup) == nil)
        #expect(setup.scheduler.scheduled == nil)
    }

    @Test func finishAndCancelRemoveTheNotification() async throws {
        let finished = try await Self.makeSetup()
        try await Self.complete(finished.benchSets[0], in: finished)
        try await FinishWorkoutUseCase(repository: finished.workouts, scheduler: finished.scheduler, now: finished.clock.now).execute()
        #expect(finished.scheduler.scheduled == nil)
        #expect(finished.workouts.workouts.first?.rest == nil)

        let cancelled = try await Self.makeSetup()
        try await Self.complete(cancelled.benchSets[0], in: cancelled)
        try await CancelWorkoutUseCase(repository: cancelled.workouts, scheduler: cancelled.scheduler).execute()
        #expect(cancelled.scheduler.scheduled == nil)
    }

    @Test func restTriggerIsTheLatestCompletedSet() async throws {
        let setup = try await Self.makeSetup()
        try await Self.complete(setup.benchSets[0], in: setup)
        setup.clock.advance(by: 60)
        try await Self.complete(setup.squatSets[0], in: setup)
        setup.clock.advance(by: 60)
        try await Self.complete(setup.benchSets[0], in: setup)

        let active = try #require(try await setup.workouts.activeWorkout())
        let trigger = try #require(active.restTrigger)
        #expect(trigger.entry.id == setup.squatSets[0].id)
        #expect(trigger.number == 1)
        let next = try #require(active.nextPlannedSet(after: trigger))
        #expect(next.entry.id == setup.benchSets[1].id)
        #expect(next.number == 2)
    }
}
