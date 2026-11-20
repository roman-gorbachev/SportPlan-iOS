import Domain
import Foundation
import Testing

struct WorkoutUseCaseTests {
    private static func makeDayDetail(exercises: [LibraryExercise], sets: Int = 3) -> ProgramDayDetail {
        let day = ProgramDay(id: UUID(), programId: UUID(), name: "Грудь и трицепс", label: "A", position: 0)
        let items = exercises.enumerated().map { position, exercise in
            let planned = PlannedExercise(
                id: UUID(),
                programDayId: day.id,
                exerciseId: exercise.id,
                position: position,
                targetSets: sets,
                targetReps: exercise.metric == .weightReps ? RepRange(min: 8, max: 12) : nil,
                restSeconds: 120
            )
            return PlannedExerciseItem(plannedExercise: planned, exercise: exercise)
        }
        return ProgramDayDetail(day: day, programName: "Сила 3×", exercises: items)
    }

    private static func startEmpty(_ repository: FakeWorkoutRepository, clock: TestClock = TestClock()) async throws {
        try await StartEmptyWorkoutUseCase(repository: repository, now: clock.now).execute()
    }

    private static func active(_ repository: FakeWorkoutRepository) async throws -> ActiveWorkout {
        return try #require(try await repository.activeWorkout())
    }

    @Test func startFromDayCopiesSnapshotTargetsAndPlannedRows() async throws {
        let bench = DomainFixtures.makeLibraryExercise()
        let plank = DomainFixtures.makeLibraryExercise(name: "Планка", kind: nil, metric: .duration)
        let detail = Self.makeDayDetail(exercises: [bench, plank])
        let workouts = FakeWorkoutRepository(
            library: [bench, plank],
            previousSets: [bench.id: [DomainFixtures.makeSet(position: 0, kilograms: 60, reps: 9)]]
        )
        let useCase = StartWorkoutFromDayUseCase(
            workoutRepository: workouts,
            programRepository: FakeProgramRepository(dayDetails: [detail]),
            now: TestClock().now
        )
        try await useCase.execute(dayId: detail.day.id)

        let active = try await Self.active(workouts)
        #expect(active.workout.programDay == ProgramDaySnapshot(programDayId: detail.day.id, name: "Грудь и трицепс", label: "A"))
        #expect(active.workout.startedAt == DomainFixtures.referenceDate)
        #expect(active.exercises.map(\.exercise.id) == [bench.id, plank.id])
        #expect(active.exercises.map(\.workoutExercise.targetSets) == [3, 3])
        #expect(active.exercises.map(\.workoutExercise.restSeconds) == [120, 120])
        #expect(active.exercises[0].sets.map(\.reps) == [9, 9, 9])
        #expect(active.exercises[0].sets.map(\.weight) == Array(repeating: Weight(kilograms: 60), count: 3))
        #expect(active.exercises[1].sets.map(\.durationSeconds) == [nil, nil, nil])
        #expect(active.incompleteSetCount == 6)
    }

    @Test func startFromDayUsesStartWeightAndCopiesTargetDuration() async throws {
        let bench = DomainFixtures.makeLibraryExercise()
        let plank = DomainFixtures.makeLibraryExercise(name: "Планка", kind: nil, metric: .duration)
        let day = ProgramDay(id: UUID(), programId: UUID(), name: "Грудь", label: nil, position: 0)
        let items = [
            PlannedExerciseItem(plannedExercise: PlannedExercise(
                id: UUID(), programDayId: day.id, exerciseId: bench.id, position: 0, targetSets: 2,
                targetReps: RepRange(min: 8, max: 12), restSeconds: 120, startWeight: Weight(kilograms: 50)
            ), exercise: bench),
            PlannedExerciseItem(plannedExercise: PlannedExercise(
                id: UUID(), programDayId: day.id, exerciseId: plank.id, position: 1, targetSets: 2,
                targetReps: nil, restSeconds: 60, targetDurationSeconds: 45
            ), exercise: plank),
        ]
        let detail = ProgramDayDetail(day: day, programName: "Сила", exercises: items)
        let workouts = FakeWorkoutRepository(library: [bench, plank])
        let useCase = StartWorkoutFromDayUseCase(
            workoutRepository: workouts,
            programRepository: FakeProgramRepository(dayDetails: [detail]),
            now: TestClock().now
        )
        try await useCase.execute(dayId: day.id)

        let active = try await Self.active(workouts)
        #expect(active.exercises[0].sets.map(\.weight) == [Weight(kilograms: 50), Weight(kilograms: 50)])
        #expect(active.exercises[1].workoutExercise.targetDurationSeconds == 45)
        #expect(active.exercises[1].sets.map(\.durationSeconds) == [45, 45])
    }

    @Test func startIsRejectedWhileAnotherWorkoutIsActive() async throws {
        let workouts = FakeWorkoutRepository()
        try await Self.startEmpty(workouts)
        await #expect(throws: WorkoutError.alreadyActive) {
            try await Self.startEmpty(workouts)
        }
        let detail = Self.makeDayDetail(exercises: [])
        let fromDay = StartWorkoutFromDayUseCase(
            workoutRepository: workouts,
            programRepository: FakeProgramRepository(dayDetails: [detail]),
            now: TestClock().now
        )
        await #expect(throws: WorkoutError.alreadyActive) {
            try await fromDay.execute(dayId: detail.day.id)
        }
        #expect(workouts.workouts.count == 1)
    }

    @Test func addedExerciseIsUnplannedAndCannotRepeat() async throws {
        let bench = DomainFixtures.makeLibraryExercise()
        let equipment = try #require(bench.equipment)
        let workouts = FakeWorkoutRepository(library: [bench])
        try await Self.startEmpty(workouts)
        let useCase = AddExerciseToWorkoutUseCase(
            workoutRepository: workouts,
            exerciseRepository: FakeExerciseRepository(library: [bench]),
            equipmentRepository: FakeEquipmentRepository(equipment: [equipment])
        )
        try await useCase.execute(exerciseId: bench.id)

        let item = try #require(try await Self.active(workouts).exercises.first)
        #expect(item.workoutExercise.targetSets == nil)
        #expect(item.workoutExercise.targetReps == nil)
        #expect(item.sets.map(\.weight) == [Weight(kilograms: 20)])
        await #expect(throws: WorkoutError.exerciseAlreadyInWorkout) {
            try await useCase.execute(exerciseId: bench.id)
        }
        await #expect(throws: WorkoutError.exerciseUnavailable) {
            try await useCase.execute(exerciseId: UUID())
        }
    }

    @Test func completingASetWritesValuesAndTime() async throws {
        let bench = DomainFixtures.makeLibraryExercise()
        let clock = TestClock()
        let workouts = FakeWorkoutRepository(library: [bench])
        try await Self.startEmpty(workouts, clock: clock)
        let item = WorkoutExercise(id: UUID(), workoutId: try await Self.active(workouts).id, exerciseId: bench.id, position: 0, targetSets: nil, targetReps: nil, restSeconds: 90)
        let entry = DomainFixtures.makeSet(workoutExerciseId: item.id, position: 0, kilograms: 60, reps: 8, completedAt: nil)
        try await workouts.addExercise(item, sets: [entry])
        clock.advance(by: 60)

        let draft = SetEntryDraft(weight: Weight(kilograms: 62.5), reps: 7, durationSeconds: nil)
        try await CompleteSetUseCase(repository: workouts, scheduler: FakeRestNotificationScheduler(), now: clock.now).execute(setId: entry.id, draft: draft)

        let stored = try #require(workouts.sets.first)
        #expect(stored.weight == Weight(kilograms: 62.5))
        #expect(stored.reps == 7)
        #expect(stored.completedAt == DomainFixtures.referenceDate.addingTimeInterval(60))
        await #expect(throws: WorkoutError.invalidSet) {
            try await UpdateSetUseCase(repository: workouts).execute(setId: entry.id, draft: SetEntryDraft(weight: .zero, reps: nil, durationSeconds: nil))
        }
    }

    @Test func stopwatchWritesTheElapsedDuration() async throws {
        let plank = DomainFixtures.makeLibraryExercise(name: "Планка", kind: nil, metric: .duration)
        let clock = TestClock()
        let workouts = FakeWorkoutRepository(library: [plank])
        try await Self.startEmpty(workouts, clock: clock)
        let item = WorkoutExercise(id: UUID(), workoutId: try await Self.active(workouts).id, exerciseId: plank.id, position: 0, targetSets: nil, targetReps: nil, restSeconds: 90)
        let entry = DomainFixtures.makeSet(workoutExerciseId: item.id, position: 0, kilograms: 0, reps: nil, completedAt: nil)
        try await workouts.addExercise(item, sets: [entry])

        try await StartTimedSetUseCase(repository: workouts, now: clock.now).execute(setId: entry.id)
        #expect(workouts.sets.first?.state == .running)
        clock.advance(by: 74.6)
        try await StopTimedSetUseCase(repository: workouts, scheduler: FakeRestNotificationScheduler(), now: clock.now).execute(setId: entry.id)

        let stored = try #require(workouts.sets.first)
        #expect(stored.state == .completed)
        #expect(stored.durationSeconds == 75)
        await #expect(throws: WorkoutError.invalidSet) {
            try await StopTimedSetUseCase(repository: workouts, scheduler: FakeRestNotificationScheduler(), now: clock.now).execute(setId: entry.id)
        }
    }

    @Test func addSetCopiesThePreviousRow() async throws {
        let bench = DomainFixtures.makeLibraryExercise()
        let workouts = FakeWorkoutRepository(library: [bench])
        try await Self.startEmpty(workouts)
        let item = WorkoutExercise(id: UUID(), workoutId: try await Self.active(workouts).id, exerciseId: bench.id, position: 0, targetSets: nil, targetReps: nil, restSeconds: 90)
        try await workouts.addExercise(item, sets: [DomainFixtures.makeSet(workoutExerciseId: item.id, position: 0, kilograms: 60, reps: 8)])

        let useCase = AddSetUseCase(repository: workouts)
        try await useCase.execute(workoutExerciseId: item.id, isWarmup: false)
        try await useCase.execute(workoutExerciseId: item.id, isWarmup: true)

        let sets = try #require(try await Self.active(workouts).exercises.first).sets
        #expect(sets.map(\.isWarmup) == [true, false, false])
        #expect(sets.map(\.weight) == [Weight(kilograms: 20), Weight(kilograms: 60), Weight(kilograms: 60)])
        #expect(sets.map(\.state) == [.planned, .completed, .planned])
    }

    @Test func finishDropsUnfinishedRowsAndEmptyExercises() async throws {
        let bench = DomainFixtures.makeLibraryExercise()
        let dips = DomainFixtures.makeLibraryExercise(name: "Брусья", kind: nil)
        let workouts = FakeWorkoutRepository(library: [bench, dips])
        try await Self.startEmpty(workouts)
        let workoutId = try await Self.active(workouts).id
        let benchItem = WorkoutExercise(id: UUID(), workoutId: workoutId, exerciseId: bench.id, position: 0, targetSets: nil, targetReps: nil, restSeconds: 90)
        let dipsItem = WorkoutExercise(id: UUID(), workoutId: workoutId, exerciseId: dips.id, position: 1, targetSets: nil, targetReps: nil, restSeconds: 90)
        try await workouts.addExercise(benchItem, sets: [
            DomainFixtures.makeSet(workoutExerciseId: benchItem.id, position: 0, kilograms: 60, reps: 8),
            DomainFixtures.makeSet(workoutExerciseId: benchItem.id, position: 1, kilograms: 60, reps: 8, completedAt: nil),
        ])
        try await workouts.addExercise(dipsItem, sets: [
            DomainFixtures.makeSet(workoutExerciseId: dipsItem.id, position: 0, kilograms: 0, reps: 10, completedAt: nil),
        ])
        #expect(try await Self.active(workouts).incompleteSetCount == 2)

        let clock = TestClock()
        try await FinishWorkoutUseCase(repository: workouts, scheduler: FakeRestNotificationScheduler(), now: clock.now).execute()

        #expect(try await workouts.activeWorkout() == nil)
        #expect(workouts.workouts.first?.finishedAt == DomainFixtures.referenceDate)
        #expect(workouts.workoutExercises.map(\.id) == [benchItem.id])
        #expect(workouts.sets.count == 1)
    }

    @Test func finishWithoutCompletedSetsDiscardsTheWorkout() async throws {
        let workouts = FakeWorkoutRepository()
        try await Self.startEmpty(workouts)
        try await FinishWorkoutUseCase(repository: workouts, scheduler: FakeRestNotificationScheduler(), now: TestClock().now).execute()
        #expect(workouts.workouts.isEmpty)
    }

    @Test func cancelRemovesEverything() async throws {
        let workouts = FakeWorkoutRepository()
        try await Self.startEmpty(workouts)
        try await CancelWorkoutUseCase(repository: workouts, scheduler: FakeRestNotificationScheduler()).execute()
        #expect(workouts.workouts.isEmpty)
        await #expect(throws: WorkoutError.noActiveWorkout) {
            try await CancelWorkoutUseCase(repository: workouts, scheduler: FakeRestNotificationScheduler()).execute()
        }
    }

    @Test func blankNoteIsStoredAsNil() async throws {
        let workouts = FakeWorkoutRepository()
        try await Self.startEmpty(workouts)
        let workoutId = try await Self.active(workouts).id
        let useCase = UpdateWorkoutNoteUseCase(repository: workouts)
        try await useCase.execute(workoutId: workoutId, note: "  Плечо не беспокоило \n")
        #expect(workouts.workouts.first?.note == "Плечо не беспокоило")
        try await useCase.execute(workoutId: workoutId, note: "   ")
        #expect(workouts.workouts.first?.note == nil)
    }
}
