import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

@MainActor
struct EquipmentEditorViewModelTests {
    private static func makeViewModel(target: EquipmentEditorTarget, database: AppDatabase) -> EquipmentEditorViewModel {
        let repository = EquipmentRepositoryImpl(database: database)
        return EquipmentEditorViewModel(
            target: target,
            loadEquipmentEditor: LoadEquipmentEditorUseCase(repository: repository),
            saveEquipment: SaveEquipmentUseCase(repository: repository, now: { return DatabaseFixtures.referenceDate }),
            archiveEquipment: ArchiveEquipmentUseCase(repository: repository)
        )
    }

    private static func data(of viewModel: EquipmentEditorViewModel) throws -> EquipmentEditorUiData {
        guard case let .success(data) = viewModel.editorUiState else {
            throw EquipmentError.notFound
        }
        return data
    }

    @Test func newEquipmentCannotBeSavedWithoutName() async throws {
        let viewModel = Self.makeViewModel(target: .new(kind: .barbell), database: try DatabaseFixtures.makeDatabase())
        await viewModel.load()
        #expect(try Self.data(of: viewModel).canSave == false)

        viewModel.updateName("Олимпийский гриф")
        #expect(try Self.data(of: viewModel).canSave)

        viewModel.updateName("   ")
        #expect(try Self.data(of: viewModel).canSave == false)
    }

    @Test func invalidWeightTextDisablesSave() async throws {
        let viewModel = Self.makeViewModel(target: .new(kind: .barbell), database: try DatabaseFixtures.makeDatabase())
        await viewModel.load()
        viewModel.updateName("Гриф")

        viewModel.updateWeightStep("abc")
        #expect(try Self.data(of: viewModel).canSave == false)

        viewModel.updateWeightStep("1,25")
        #expect(try Self.data(of: viewModel).canSave)

        viewModel.updateBaseWeight("")
        #expect(try Self.data(of: viewModel).canSave == false)
    }

    @Test func baseWeightIsIgnoredForKindsWithoutIt() async throws {
        let viewModel = Self.makeViewModel(target: .new(kind: .dumbbell), database: try DatabaseFixtures.makeDatabase())
        await viewModel.load()
        viewModel.updateName("Гантели")
        viewModel.updateBaseWeight("")

        let data = try Self.data(of: viewModel)
        #expect(data.kind.hasBaseWeight == false)
        #expect(data.canSave)
    }

    @Test func savesNewEquipmentWithParsedWeights() async throws {
        let viewModel = Self.makeViewModel(target: .new(kind: .plateLoadedMachine), database: try DatabaseFixtures.makeDatabase())
        await viewModel.load()
        viewModel.updateName("Жим ногами")
        viewModel.updateBaseWeight("50")
        viewModel.updateWeightStep("5")

        let saved = try #require(await viewModel.save())
        #expect(saved.name == "Жим ногами")
        #expect(saved.baseWeight == Weight(kilograms: 50))
        #expect(saved.weightStep == Weight(kilograms: 5))
    }

    @Test func kindIsLockedForEquipmentUsedByExercise() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let equipment = DatabaseFixtures.makeEquipment()
        let exercise = DatabaseFixtures.makeExercise(load: .equipment(id: equipment.id))
        try await database.writer.write { db in
            try EquipmentRecord(equipment).insert(db)
            try ExerciseRecord(exercise).insert(db)
        }
        let viewModel = Self.makeViewModel(target: .existing(id: equipment.id), database: database)
        await viewModel.load()

        viewModel.updateKind(.dumbbell)

        let data = try Self.data(of: viewModel)
        #expect(data.isKindLocked)
        #expect(data.exerciseCount == 1)
        #expect(data.kind == .barbell)
    }

    @Test func unusedEquipmentKindCanChange() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let equipment = DatabaseFixtures.makeEquipment()
        try await database.writer.write { db in
            try EquipmentRecord(equipment).insert(db)
        }
        let viewModel = Self.makeViewModel(target: .existing(id: equipment.id), database: database)
        await viewModel.load()

        viewModel.updateKind(.selectorizedMachine)

        let data = try Self.data(of: viewModel)
        #expect(data.isKindLocked == false)
        #expect(data.kind == .selectorizedMachine)
        #expect(data.canSave)
    }

    @Test func archiveHidesEquipment() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let equipment = DatabaseFixtures.makeEquipment()
        try await database.writer.write { db in
            try EquipmentRecord(equipment).insert(db)
        }
        let viewModel = Self.makeViewModel(target: .existing(id: equipment.id), database: database)
        await viewModel.load()

        #expect(await viewModel.archive())
        let stored = try await EquipmentRepositoryImpl(database: database).equipment(id: equipment.id)
        #expect(stored?.isArchived == true)
    }
}
