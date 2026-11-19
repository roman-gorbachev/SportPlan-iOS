import Domain
import Foundation
import GRDB
import Testing
import WorkoutActivity
@testable import sportplan

@MainActor
struct WorkoutActivityCoordinatorTests {
    private static let pollInterval = Duration.milliseconds(10)
    private static let pollAttempts = 300
    private static let settleDelay = Duration.milliseconds(150)
    private static let loadedWeight = Weight(kilograms: 60)

    private struct Fixture {
        let day: ProgramDay
        let workouts: WorkoutRepositoryImpl
        let store: ActiveWorkoutStore
        let coordinator: WorkoutActivityCoordinator
        let controller: RecordingWorkoutActivityController
        let scheduler: RecordingRestNotificationScheduler
        let now: @Sendable () -> Date
    }

    private static func makeFixture() async throws -> Fixture {
        let database = try DatabaseFixtures.makeDatabase()
        let bar = DatabaseFixtures.makeEquipment()
        let bench = DatabaseFixtures.makeExercise(load: .equipment(id: bar.id))
        try await database.writer.write { db in
            try EquipmentRecord(bar).insert(db)
            try ExerciseRecord(bench).insert(db)
        }
        let programs = ProgramRepositoryImpl(database: database)
        let program = DatabaseFixtures.makeProgram()
        let day = DatabaseFixtures.makeDay(programId: program.id)
        _ = try await programs.createProgram(program, firstDay: day)
        _ = try await programs.addPlannedExercise(DatabaseFixtures.makePlannedExercise(dayId: day.id, exerciseId: bench.id))
        let workouts = WorkoutRepositoryImpl(database: database)
        let store = ActiveWorkoutStore(observeActiveWorkout: ObserveActiveWorkoutUseCase(repository: workouts))
        let controller = RecordingWorkoutActivityController()
        let coordinator = WorkoutActivityCoordinator(
            store: store,
            loadPlates: LoadPlatesUseCase(repository: PlateRepositoryImpl(database: database)),
            controller: controller
        )
        let now: @Sendable () -> Date = { return Date() }
        try await StartWorkoutFromDayUseCase(workoutRepository: workouts, programRepository: programs, now: now)
            .execute(dayId: day.id)
        return Fixture(
            day: day,
            workouts: workouts,
            store: store,
            coordinator: coordinator,
            controller: controller,
            scheduler: RecordingRestNotificationScheduler(),
            now: now
        )
    }

    private static func startObserving(_ fixture: Fixture) -> [Task<Void, Never>] {
        let store = fixture.store
        let coordinator = fixture.coordinator
        return [
            Task {
                await store.observe()
            },
            Task {
                await coordinator.observe()
            },
        ]
    }

    private static func shown(
        _ fixture: Fixture,
        where condition: (RecordingWorkoutActivityController.Shown) -> Bool
    ) async throws -> RecordingWorkoutActivityController.Shown {
        for _ in 0..<pollAttempts {
            if let last = fixture.controller.shown.last, condition(last) {
                return last
            }
            try await Task.sleep(for: pollInterval)
        }
        throw WorkoutError.noActiveWorkout
    }

    private static func waitForEnd(_ fixture: Fixture, count: Int) async throws {
        for _ in 0..<pollAttempts {
            if fixture.controller.endCount >= count {
                return
            }
            try await Task.sleep(for: pollInterval)
        }
        throw WorkoutError.noActiveWorkout
    }

    private static func sets(_ fixture: Fixture) async throws -> [SetEntry] {
        let active = try #require(try await fixture.workouts.activeWorkout())
        return try #require(active.exercises.first).sets
    }

    private static func complete(_ entry: SetEntry, in fixture: Fixture) async throws {
        try await CompleteSetUseCase(repository: fixture.workouts, scheduler: fixture.scheduler, now: fixture.now)
            .execute(setId: entry.id, draft: SetEntryDraft(entry))
    }

    @Test func showsTheCurrentSetThenRestAndEndsOnFinish() async throws {
        let fixture = try await Self.makeFixture()
        let tasks = Self.startObserving(fixture)
        defer {
            tasks.forEach { task in task.cancel() }
        }

        let first = try await Self.shown(fixture) { shown in return shown.content.phase == .set }
        #expect(first.content.exerciseName == "Жим лёжа")
        #expect(first.content.setText == "подход 1 · 8–12 повт.")
        #expect(first.content.loadText == "20 × 8")
        #expect(first.content.plates.isEmpty)
        #expect(first.staleDate == nil)
        #expect(first.attributes.workoutId == fixture.store.state.workout?.id)

        let sets = try await Self.sets(fixture)
        var heavier = SetEntryDraft(sets[1])
        heavier.weight = Self.loadedWeight
        try await UpdateSetUseCase(repository: fixture.workouts).execute(setId: sets[1].id, draft: heavier)
        try await Self.complete(sets[0], in: fixture)

        let resting = try await Self.shown(fixture) { shown in return shown.content.phase == .rest }
        #expect(resting.content.setText == "подход 2 · 8–12 повт.")
        #expect(resting.content.loadText == "60 × 8")
        #expect(resting.content.nextText == "дальше 60 × 8")
        #expect(resting.content.readyText == "Пора: Жим лёжа, подход 2")
        #expect(resting.content.plates.map(\.kilograms) == [20])
        #expect(resting.staleDate != nil)
        #expect(resting.staleDate == resting.content.restEndsAt)

        try await FinishWorkoutUseCase(repository: fixture.workouts, scheduler: fixture.scheduler, now: fixture.now).execute()
        try await Self.waitForEnd(fixture, count: 1)
    }

    @Test func unrelatedChangesAreNotSentAgain() async throws {
        let fixture = try await Self.makeFixture()
        let tasks = Self.startObserving(fixture)
        defer {
            tasks.forEach { task in task.cancel() }
        }
        _ = try await Self.shown(fixture) { shown in return shown.content.phase == .set }
        let count = fixture.controller.shown.count
        let workoutId = try #require(fixture.store.state.workout?.id)

        try await UpdateWorkoutNoteUseCase(repository: fixture.workouts).execute(workoutId: workoutId, note: "Плечо тянет")
        for _ in 0..<Self.pollAttempts where fixture.store.state.workout?.workout.note == nil {
            try await Task.sleep(for: Self.pollInterval)
        }
        try await Task.sleep(for: Self.settleDelay)

        #expect(fixture.store.state.workout?.workout.note == "Плечо тянет")
        #expect(fixture.controller.shown.count == count)
    }

    @Test func lastSetRestOffersToFinishThenShowsAllSetsDone() async throws {
        let fixture = try await Self.makeFixture()
        let tasks = Self.startObserving(fixture)
        defer {
            tasks.forEach { task in task.cancel() }
        }
        _ = try await Self.shown(fixture) { shown in return shown.content.phase == .set }
        for entry in try await Self.sets(fixture) {
            try await Self.complete(entry, in: fixture)
        }

        let resting = try await Self.shown(fixture) { shown in
            return shown.content.phase == .rest && shown.content.exerciseName.isEmpty
        }
        #expect(resting.content.readyText == "Можно завершать тренировку")
        #expect(resting.content.nextText.isEmpty)

        try await SkipRestUseCase(repository: fixture.workouts, scheduler: fixture.scheduler).execute()
        let done = try await Self.shown(fixture) { shown in return shown.content.phase == .finishedSets }
        #expect(done.content.restEndsAt == nil)
        #expect(done.staleDate == nil)
    }

    @Test func endsAStaleActivityWhenThereIsNoWorkout() async throws {
        let fixture = try await Self.makeFixture()
        try await CancelWorkoutUseCase(repository: fixture.workouts, scheduler: fixture.scheduler).execute()
        let tasks = Self.startObserving(fixture)
        defer {
            tasks.forEach { task in task.cancel() }
        }

        try await Self.waitForEnd(fixture, count: 1)
        #expect(fixture.controller.shown.isEmpty)
    }
}
