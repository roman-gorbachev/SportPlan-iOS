import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

@MainActor
struct ProgramDayViewModelsTests {
    private static let pollInterval = Duration.milliseconds(10)
    private static let pollAttempts = 300

    private struct DayFixture {
        let database: AppDatabase
        let day: ProgramDay
        let bench: Exercise
        let plank: Exercise
    }

    private static func makeFixture() async throws -> DayFixture {
        let database = try DatabaseFixtures.makeDatabase()
        let bench = DatabaseFixtures.makeExercise(load: .bodyweight)
        var timed = DatabaseFixtures.makeExercise(load: .bodyweight)
        timed.name = "Планка"
        timed.metric = .duration
        let plank = timed
        try await database.writer.write { db in
            try ExerciseRecord(bench).insert(db)
            try ExerciseRecord(plank).insert(db)
        }
        let program = DatabaseFixtures.makeProgram()
        let day = DatabaseFixtures.makeDay(programId: program.id)
        _ = try await ProgramRepositoryImpl(database: database).createProgram(program, firstDay: day)
        return DayFixture(database: database, day: day, bench: bench, plank: plank)
    }

    private static func makeGoals(target: PlannedExerciseGoalsTarget, database: AppDatabase) -> PlannedExerciseGoalsViewModel {
        let programs = ProgramRepositoryImpl(database: database)
        return PlannedExerciseGoalsViewModel(
            target: target,
            updateTargets: UpdatePlannedExerciseTargetsUseCase(
                programRepository: programs,
                exerciseRepository: ExerciseRepositoryImpl(database: database)
            ),
            removePlannedExercise: RemovePlannedExerciseUseCase(repository: programs)
        )
    }

    private static func makePicker(dayId: UUID, database: AppDatabase) -> ExercisePickerViewModel {
        let workouts = WorkoutRepositoryImpl(database: database)
        return makePicker(
            destination: .day(id: dayId, shortTitle: "A", fullTitle: "A · Грудь и трицепс"),
            database: database,
            store: ActiveWorkoutStore(observeActiveWorkout: ObserveActiveWorkoutUseCase(repository: workouts))
        )
    }

    private static func makePicker(
        destination: ExercisePickerDestination,
        database: AppDatabase,
        store: ActiveWorkoutStore
    ) -> ExercisePickerViewModel {
        let programs = ProgramRepositoryImpl(database: database)
        let exercises = ExerciseRepositoryImpl(database: database)
        let workouts = WorkoutRepositoryImpl(database: database)
        return ExercisePickerViewModel(
            target: ExercisePickerTarget(destination: destination),
            observeExerciseLibrary: ObserveExerciseLibraryUseCase(repository: exercises),
            observeProgramDay: ObserveProgramDayUseCase(repository: programs),
            addExerciseToDay: AddExerciseToDayUseCase(programRepository: programs, exerciseRepository: exercises),
            workoutStore: store,
            addExerciseToWorkout: AddExerciseToWorkoutUseCase(
                workoutRepository: workouts,
                exerciseRepository: exercises,
                equipmentRepository: EquipmentRepositoryImpl(database: database)
            )
        )
    }

    private static func goalsData(_ viewModel: PlannedExerciseGoalsViewModel) throws -> PlannedExerciseGoalsUiData {
        guard case let .success(data) = viewModel.goalsUiState else {
            throw ProgramError.notFound
        }
        return data
    }

    private static func pickerUntil(
        _ viewModel: ExercisePickerViewModel,
        condition: (ExercisePickerUiData) -> Bool
    ) async throws -> ExercisePickerUiData? {
        for _ in 0..<pollAttempts {
            if case let .success(data) = viewModel.pickerUiState, condition(data) {
                return data
            }
            try await Task.sleep(for: pollInterval)
        }
        return nil
    }

    @Test func goalsForTimedExerciseHaveNoReps() async throws {
        let fixture = try await Self.makeFixture()
        let planned = try await ProgramRepositoryImpl(database: fixture.database).addPlannedExercise(PlannedExercise(
            id: UUID(),
            programDayId: fixture.day.id,
            exerciseId: fixture.plank.id,
            position: 0,
            targetSets: 3,
            targetReps: nil,
            restSeconds: 60
        ))
        let target = PlannedExerciseGoalsTarget(
            plannedExerciseId: planned.id,
            exercise: LibraryExercise(exercise: fixture.plank, equipment: nil),
            dayTitle: "A · Грудь и трицепс",
            targets: planned.targets
        )
        let viewModel = Self.makeGoals(target: target, database: fixture.database)
        let data = try Self.goalsData(viewModel)
        #expect(data.targets.showsReps == false)
        #expect(data.targets.startWeight == nil)
        #expect(data.targets.showsDuration)
        #expect(data.targets.durationText == "1:00")

        viewModel.step(.incrementSets)
        viewModel.step(.incrementRest)
        viewModel.step(.incrementDuration)
        #expect(await viewModel.save())
        let stored = try await ProgramRepositoryImpl(database: fixture.database).plannedExercise(id: planned.id)
        #expect(stored?.targetSets == 4)
        #expect(stored?.restSeconds == 75)
        #expect(stored?.targetReps == nil)
        #expect(stored?.targetDurationSeconds == 65)
    }

    @Test func goalsStoreTheStartWeight() async throws {
        let fixture = try await Self.makeFixture()
        let repository = ProgramRepositoryImpl(database: fixture.database)
        let planned = try await repository.addPlannedExercise(DatabaseFixtures.makePlannedExercise(dayId: fixture.day.id, exerciseId: fixture.bench.id))
        let target = PlannedExerciseGoalsTarget(
            plannedExerciseId: planned.id,
            exercise: LibraryExercise(exercise: fixture.bench, equipment: nil),
            dayTitle: "A · Грудь и трицепс",
            targets: planned.targets
        )
        let viewModel = Self.makeGoals(target: target, database: fixture.database)
        #expect(try Self.goalsData(viewModel).targets.startWeight?.canDecrement == false)
        viewModel.step(.incrementStartWeight)
        viewModel.step(.incrementStartWeight)
        #expect(try Self.goalsData(viewModel).targets.startWeight?.valueText == "5 кг")
        #expect(await viewModel.save())
        #expect(try await repository.plannedExercise(id: planned.id)?.startWeight == Weight(kilograms: 5))
    }

    @Test func goalsRepBoundsPullEachOtherAndRemoveWorks() async throws {
        let fixture = try await Self.makeFixture()
        let repository = ProgramRepositoryImpl(database: fixture.database)
        let planned = try await repository.addPlannedExercise(DatabaseFixtures.makePlannedExercise(dayId: fixture.day.id, exerciseId: fixture.bench.id))
        let target = PlannedExerciseGoalsTarget(
            plannedExerciseId: planned.id,
            exercise: LibraryExercise(exercise: fixture.bench, equipment: nil),
            dayTitle: "A · Грудь и трицепс",
            targets: PlannedExerciseTargets(sets: 3, reps: RepRange(min: 8, max: 8), restSeconds: 90)
        )
        let viewModel = Self.makeGoals(target: target, database: fixture.database)
        viewModel.step(.incrementMinimumReps)
        let data = try Self.goalsData(viewModel)
        #expect(data.targets.minimumRepsText == "9")
        #expect(data.targets.maximumRepsText == "9")

        #expect(await viewModel.remove())
        #expect(try await repository.plannedExercise(id: planned.id) == nil)
    }

    @Test func pickerMarksExercisesInDayAndAddsOnTap() async throws {
        let fixture = try await Self.makeFixture()
        _ = try await ProgramRepositoryImpl(database: fixture.database).addPlannedExercise(
            DatabaseFixtures.makePlannedExercise(dayId: fixture.day.id, exerciseId: fixture.bench.id)
        )
        let viewModel = Self.makePicker(dayId: fixture.day.id, database: fixture.database)
        let libraryTask = Task {
            await viewModel.observeLibrary()
        }
        let dayTask = Task {
            await viewModel.observeAddedExercises()
        }
        defer {
            libraryTask.cancel()
            dayTask.cancel()
        }

        let initial = try #require(try await Self.pickerUntil(viewModel) { data in
            return !data.sections.isEmpty
        })
        let items = initial.sections.flatMap(\.exercises)
        #expect(items.first { item in return item.id == fixture.bench.id }?.isAdded == true)
        #expect(items.first { item in return item.id == fixture.plank.id }?.isAdded == false)

        await viewModel.add(exerciseId: fixture.plank.id)
        let updated = try await Self.pickerUntil(viewModel) { data in
            return data.sections.flatMap(\.exercises).allSatisfy(\.isAdded)
        }
        #expect(updated != nil)
        let plannedCount = try await fixture.database.reader.read { db in
            return try PlannedExerciseRecord.fetchCount(db)
        }
        #expect(plannedCount == 2)
    }

    @Test func exerciseCreatedFromTheWorkoutPickerJoinsTheWorkout() async throws {
        let fixture = try await Self.makeFixture()
        let workouts = WorkoutRepositoryImpl(database: fixture.database)
        try await StartEmptyWorkoutUseCase(repository: workouts, now: { return Date() }).execute()
        let workoutId = try #require(try await workouts.activeWorkout()?.workout.id)
        let store = ActiveWorkoutStore(observeActiveWorkout: ObserveActiveWorkoutUseCase(repository: workouts))
        let viewModel = Self.makePicker(destination: .workout(id: workoutId), database: fixture.database, store: store)
        let tasks = [
            Task {
                await store.observe()
            },
            Task {
                await viewModel.observeLibrary()
            },
            Task {
                await viewModel.observeAddedExercises()
            },
        ]
        defer {
            tasks.forEach { task in task.cancel() }
        }
        _ = try #require(try await Self.pickerUntil(viewModel) { data in
            return !data.sections.isEmpty
        })

        #expect(await viewModel.addCreatedExercise(id: fixture.plank.id))
        let exerciseIds = try await workouts.activeWorkout()?.exercises.map(\.exercise.id)
        #expect(exerciseIds == [fixture.plank.id])
    }

    @Test func exerciseCreatedFromTheDayPickerKeepsThePickerOpen() async throws {
        let fixture = try await Self.makeFixture()
        let viewModel = Self.makePicker(dayId: fixture.day.id, database: fixture.database)

        #expect(await viewModel.addCreatedExercise(id: fixture.plank.id) == false)
    }
}
