import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

@MainActor
struct WorkoutViewModelsTests {
    private static let pollInterval = Duration.milliseconds(10)
    private static let pollAttempts = 300

    private struct Fixture {
        let database: AppDatabase
        let day: ProgramDay
        let bench: Exercise
        let plank: Exercise
        let start: WorkoutStartViewModel
        let active: ActiveWorkoutViewModel
    }

    private static func makeFixture(plannedExercises: (Exercise, Exercise) -> [Exercise]) async throws -> Fixture {
        let database = try DatabaseFixtures.makeDatabase()
        let bar = DatabaseFixtures.makeEquipment()
        let bench = DatabaseFixtures.makeExercise(load: .equipment(id: bar.id))
        var timed = DatabaseFixtures.makeExercise(load: .bodyweight)
        timed.name = "Планка"
        timed.metric = .duration
        let plank = timed
        try await database.writer.write { db in
            try EquipmentRecord(bar).insert(db)
            try ExerciseRecord(bench).insert(db)
            try ExerciseRecord(plank).insert(db)
        }
        let programs = ProgramRepositoryImpl(database: database)
        let program = DatabaseFixtures.makeProgram()
        let day = DatabaseFixtures.makeDay(programId: program.id)
        _ = try await programs.createProgram(program, firstDay: day)
        for exercise in plannedExercises(bench, plank) {
            var planned = DatabaseFixtures.makePlannedExercise(dayId: day.id, exerciseId: exercise.id)
            if exercise.metric == .duration {
                planned.targetReps = nil
            }
            _ = try await programs.addPlannedExercise(planned)
        }
        let workouts = WorkoutRepositoryImpl(database: database)
        let now: @Sendable () -> Date = { return Date() }
        let scheduler = RecordingRestNotificationScheduler()
        let start = WorkoutStartViewModel(
            observePrograms: ObserveProgramsUseCase(repository: programs),
            startWorkoutFromDay: StartWorkoutFromDayUseCase(workoutRepository: workouts, programRepository: programs, now: now),
            startEmptyWorkout: StartEmptyWorkoutUseCase(repository: workouts, now: now)
        )
        let active = ActiveWorkoutViewModel(
            observeActiveWorkout: ObserveActiveWorkoutUseCase(repository: workouts),
            loadPlates: LoadPlatesUseCase(repository: PlateRepositoryImpl(database: database)),
            addSet: AddSetUseCase(repository: workouts),
            updateSet: UpdateSetUseCase(repository: workouts),
            completeSet: CompleteSetUseCase(repository: workouts, scheduler: scheduler, now: now),
            startTimedSet: StartTimedSetUseCase(repository: workouts, now: now),
            stopTimedSet: StopTimedSetUseCase(repository: workouts, scheduler: scheduler, now: now),
            removeSet: RemoveSetUseCase(repository: workouts),
            updateWorkoutNote: UpdateWorkoutNoteUseCase(repository: workouts),
            finishWorkout: FinishWorkoutUseCase(repository: workouts, scheduler: scheduler, now: now),
            cancelWorkout: CancelWorkoutUseCase(repository: workouts, scheduler: scheduler)
        )
        return Fixture(database: database, day: day, bench: bench, plank: plank, start: start, active: active)
    }

    private static func until(
        _ viewModel: ActiveWorkoutViewModel,
        condition: (ActiveWorkoutUiState) -> Bool
    ) async throws -> ActiveWorkoutUiState? {
        for _ in 0..<pollAttempts {
            if condition(viewModel.activeWorkoutUiState) {
                return viewModel.activeWorkoutUiState
            }
            try await Task.sleep(for: pollInterval)
        }
        return nil
    }

    private static func data(
        _ viewModel: ActiveWorkoutViewModel,
        condition: (ActiveWorkoutUiData) -> Bool = { _ in return true }
    ) async throws -> ActiveWorkoutUiData {
        let state = try await until(viewModel) { state in
            guard case let .success(data) = state else {
                return false
            }
            return condition(data)
        }
        guard case let .success(data)? = state else {
            throw WorkoutError.noActiveWorkout
        }
        return data
    }

    private static func isNoWorkout(_ state: ActiveWorkoutUiState) -> Bool {
        guard case .noWorkout = state else {
            return false
        }
        return true
    }

    private static func weight(of row: SetRowItem) -> String? {
        guard case let .weightReps(weight, _) = row.value else {
            return nil
        }
        return weight
    }

    private static func startObserving(_ fixture: Fixture) -> [Task<Void, Never>] {
        let active = fixture.active
        return [
            Task {
                await active.observe()
            },
            Task {
                await active.loadPlateSet()
            },
        ]
    }

    @Test func startingADayShowsPlannedRows() async throws {
        let fixture = try await Self.makeFixture { bench, _ in return [bench] }
        let tasks = Self.startObserving(fixture)
        defer {
            tasks.forEach { task in task.cancel() }
        }
        #expect(try await Self.until(fixture.active, condition: Self.isNoWorkout) != nil)

        await fixture.start.start(dayId: fixture.day.id)

        let data = try await Self.data(fixture.active)
        #expect(data.title == fixture.day.name)
        #expect(data.subtitle == "День A · Сила 3×")
        let rows = try #require(data.exercises.first).sets
        #expect(rows.count == 3)
        #expect(rows.map(\.state) == [.current, .planned, .planned])
        #expect(rows.map(Self.weight) == ["20", "20", "20"])
        #expect(data.exercises.first?.summary == "0 из 3 · 8–12 повт.")
    }

    @Test func editorStopsAtTheBarAndCopiesThePreviousSet() async throws {
        let fixture = try await Self.makeFixture { bench, _ in return [bench] }
        let tasks = Self.startObserving(fixture)
        defer {
            tasks.forEach { task in task.cancel() }
        }
        await fixture.start.start(dayId: fixture.day.id)
        let rows = try #require(try await Self.data(fixture.active).exercises.first).sets

        fixture.active.openEditor(setId: rows[0].id)
        fixture.active.decrementEditorWeight()
        var editor = try #require(try await Self.data(fixture.active).editor)
        #expect(editor.weight.value == "20")
        #expect(!editor.weight.canDecrement)
        #expect(!editor.canCopyPrevious)
        for _ in 0..<4 {
            fixture.active.incrementEditorWeight()
        }
        fixture.active.incrementEditorReps()
        await fixture.active.saveEditor()

        let saved = try await Self.data(fixture.active) { data in
            return data.exercises.first?.sets.first?.state == .completed
        }
        #expect(saved.editor == nil)
        #expect(saved.exercises.first.map { item in return Self.weight(of: item.sets[0]) } == "30")
        #expect(saved.exercises.first?.sets[1].state == .current)

        fixture.active.openEditor(setId: rows[1].id)
        fixture.active.copyPreviousSet()
        editor = try #require(try await Self.data(fixture.active).editor)
        #expect(editor.weight.value == "30")
        #expect(editor.reps == "9")
        #expect(editor.saveTitle == "Записать")
    }

    @Test func stopwatchRecordsTheDuration() async throws {
        let fixture = try await Self.makeFixture { _, plank in return [plank] }
        let tasks = Self.startObserving(fixture)
        defer {
            tasks.forEach { task in task.cancel() }
        }
        await fixture.start.start(dayId: fixture.day.id)
        let row = try #require(try await Self.data(fixture.active).exercises.first?.sets.first)
        #expect(row.isTimed)
        #expect(!row.isEditable)

        await fixture.active.tapSetAction(setId: row.id)
        let running = try await Self.data(fixture.active) { data in
            return data.exercises.first?.sets.first?.state == .running
        }
        guard case let .duration(_, runningSince)? = running.exercises.first?.sets.first?.value else {
            Issue.record("Timed row expected")
            return
        }
        #expect(runningSince != nil)

        await fixture.active.tapSetAction(setId: row.id)
        _ = try await Self.data(fixture.active) { data in
            return data.exercises.first?.sets.first?.state == .completed
        }
        let setId = row.id.databaseText
        let duration = try await fixture.database.reader.read { db in
            return try SetEntryRecord.filter(Column("id") == setId).fetchOne(db)?.durationSec
        }
        #expect(duration != nil)
    }

    @Test func finishAsksAboutUnfinishedRowsAndKeepsCompletedOnes() async throws {
        let fixture = try await Self.makeFixture { bench, _ in return [bench] }
        let tasks = Self.startObserving(fixture)
        defer {
            tasks.forEach { task in task.cancel() }
        }
        await fixture.start.start(dayId: fixture.day.id)
        _ = try await Self.data(fixture.active)

        await fixture.active.requestFinish()
        var data = try await Self.data(fixture.active)
        guard case .discardEmpty? = data.confirmation else {
            Issue.record("Discard confirmation expected")
            return
        }
        fixture.active.dismissConfirmation()

        let first = try #require(data.exercises.first?.sets.first)
        await fixture.active.tapSetAction(setId: first.id)
        _ = try await Self.data(fixture.active) { data in
            return data.exercises.first?.sets.first?.state == .completed
        }
        await fixture.active.requestFinish()
        data = try await Self.data(fixture.active)
        guard case let .finish(incompleteSetCount)? = data.confirmation else {
            Issue.record("Finish confirmation expected")
            return
        }
        #expect(incompleteSetCount == 2)

        fixture.active.dismissConfirmation()
        await fixture.active.confirm(.finish(incompleteSetCount: incompleteSetCount))
        #expect(try await Self.until(fixture.active, condition: Self.isNoWorkout) != nil)
        let (finishedCount, setCount) = try await fixture.database.reader.read { db in
            let finished = try WorkoutRecord.filter(Column("finished_at") != nil).fetchCount(db)
            return (finished, try SetEntryRecord.fetchCount(db))
        }
        #expect(finishedCount == 1)
        #expect(setCount == 1)
    }

    @Test func cancelRemovesTheWorkout() async throws {
        let fixture = try await Self.makeFixture { bench, _ in return [bench] }
        let tasks = Self.startObserving(fixture)
        defer {
            tasks.forEach { task in task.cancel() }
        }
        await fixture.start.startEmpty()
        let data = try await Self.data(fixture.active)
        #expect(data.title == "Тренировка")
        #expect(data.subtitle == nil)

        fixture.active.requestCancel()
        fixture.active.dismissConfirmation()
        await fixture.active.confirm(.cancel)
        #expect(try await Self.until(fixture.active, condition: Self.isNoWorkout) != nil)
        let workoutCount = try await fixture.database.reader.read { db in
            return try WorkoutRecord.fetchCount(db)
        }
        #expect(workoutCount == 0)
    }
}
