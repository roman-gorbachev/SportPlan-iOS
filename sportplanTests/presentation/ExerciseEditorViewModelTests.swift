import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

@MainActor
struct ExerciseEditorViewModelTests {
    private static let pollInterval = Duration.milliseconds(10)
    private static let pollAttempts = 300

    private struct Setup {
        let database: AppDatabase
        let bar: Equipment
        let ezBar: Equipment
        let exercise: Exercise
    }

    private static func makeSetup(withCompletedSet: Bool) async throws -> Setup {
        let database = try DatabaseFixtures.makeDatabase()
        let bar = DatabaseFixtures.makeEquipment()
        var ezBar = DatabaseFixtures.makeEquipment()
        ezBar.name = "EZ-гриф"
        let otherBar = ezBar
        let exercise = DatabaseFixtures.makeExercise(load: .equipment(id: bar.id))
        let workout = DatabaseFixtures.makeWorkout(day: nil, finishedAt: DatabaseFixtures.referenceDate)
        let workoutExercise = DatabaseFixtures.makeWorkoutExercise(workoutId: workout.id, exerciseId: exercise.id)
        try await database.writer.write { db in
            try EquipmentRecord(bar).insert(db)
            try EquipmentRecord(otherBar).insert(db)
            try ExerciseRecord(exercise).insert(db)
            if withCompletedSet {
                try WorkoutRecord(workout).insert(db)
                try WorkoutExerciseRecord(workoutExercise).insert(db)
                try SetEntryRecord(DatabaseFixtures.makeSet(workoutExerciseId: workoutExercise.id)).insert(db)
            }
        }
        return Setup(database: database, bar: bar, ezBar: otherBar, exercise: exercise)
    }

    private static func makeViewModel(_ setup: Setup) -> ExerciseEditorViewModel {
        let equipmentRepository = EquipmentRepositoryImpl(database: setup.database)
        let exerciseRepository = ExerciseRepositoryImpl(database: setup.database)
        return ExerciseEditorViewModel(
            exerciseId: setup.exercise.id,
            loadExerciseEditor: LoadExerciseEditorUseCase(
                exerciseRepository: exerciseRepository,
                equipmentRepository: equipmentRepository
            ),
            observeEquipmentChoices: ObserveEquipmentChoicesUseCase(repository: equipmentRepository),
            updateExercise: UpdateExerciseUseCase(
                exerciseRepository: exerciseRepository,
                equipmentRepository: equipmentRepository
            ),
            archiveExercise: ArchiveExerciseUseCase(repository: exerciseRepository)
        )
    }

    private static func waitForData(
        _ viewModel: ExerciseEditorViewModel,
        condition: (ExerciseEditorUiData) -> Bool
    ) async throws -> ExerciseEditorUiData {
        for _ in 0..<pollAttempts {
            if case let .success(data) = viewModel.exerciseEditorUiState, condition(data) {
                return data
            }
            try await Task.sleep(for: pollInterval)
        }
        throw ExerciseError.notFound
    }

    private static func storedExercise(_ setup: Setup) async throws -> Exercise? {
        return try await ExerciseRepositoryImpl(database: setup.database).exercise(id: setup.exercise.id)
    }

    @Test func editorSavesNameAndEquipmentOfTheSameKind() async throws {
        let setup = try await Self.makeSetup(withCompletedSet: true)
        let viewModel = Self.makeViewModel(setup)
        let loading = Task {
            await viewModel.load()
        }
        defer {
            loading.cancel()
        }
        let data = try await Self.waitForData(viewModel) { data in
            return data.equipmentChoices.count == 2
        }
        #expect(data.equipmentLockHint != nil)
        #expect(data.equipmentChoices.first { item in
            return item.isSelected
        }?.id == setup.bar.id)
        viewModel.updateName("Жим на скамье")
        viewModel.selectEquipment(id: setup.ezBar.id)
        #expect(await viewModel.save())
        let stored = try await Self.storedExercise(setup)
        #expect(stored?.name == "Жим на скамье")
        #expect(stored?.load == .equipment(id: setup.ezBar.id))
    }

    @Test func editorArchivesTheExercise() async throws {
        let setup = try await Self.makeSetup(withCompletedSet: false)
        let viewModel = Self.makeViewModel(setup)
        let loading = Task {
            await viewModel.load()
        }
        defer {
            loading.cancel()
        }
        let data = try await Self.waitForData(viewModel) { data in
            return !data.equipmentChoices.isEmpty
        }
        #expect(data.equipmentLockHint == nil)
        viewModel.requestArchive()
        let confirming = try await Self.waitForData(viewModel) { data in
            return data.pendingArchive != nil
        }
        #expect(confirming.pendingArchive?.exerciseName == setup.exercise.name)
        #expect(await viewModel.confirmArchive())
        #expect(try await Self.storedExercise(setup)?.isArchived == true)
    }
}
