import DesignSystem
import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

@MainActor
struct PlateEditorViewModelTests {
    private static let customRGB = 0x123456

    private static func makeViewModel(target: PlateEditorTarget, database: AppDatabase) -> PlateEditorViewModel {
        let repository = PlateRepositoryImpl(database: database)
        return PlateEditorViewModel(
            target: target,
            loadPlateEditor: LoadPlateEditorUseCase(repository: repository),
            savePlate: SavePlateUseCase(repository: repository),
            deletePlate: DeletePlateUseCase(repository: repository)
        )
    }

    private static func data(of viewModel: PlateEditorViewModel) throws -> PlateEditorUiData {
        guard case let .success(data) = viewModel.editorUiState else {
            throw PlateError.notFound
        }
        return data
    }

    private static func plate(kilograms: Double, in database: AppDatabase) async throws -> Plate {
        let plates = try await PlateRepositoryImpl(database: database).plates()
        return try #require(plates.first { plate in
            return plate.weight == Weight(kilograms: kilograms)
        })
    }

    @Test func newPlateParsesDecimalCommaAndSaves() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let viewModel = Self.makeViewModel(target: .new, database: database)
        await viewModel.load()
        #expect(try Self.data(of: viewModel).canSave == false)

        viewModel.updateWeight("0,5")
        let data = try Self.data(of: viewModel)
        #expect(data.canSave)
        #expect(data.hintText == nil)
        #expect(data.preview.kilograms == 0.5)

        #expect(await viewModel.save())
        let saved = try await Self.plate(kilograms: 0.5, in: database)
        #expect(saved.color == PlatePaletteColor.red.color)
    }

    @Test func duplicateWeightShowsHintAndBlocksSave() async throws {
        let viewModel = Self.makeViewModel(target: .new, database: try DatabaseFixtures.makeDatabase())
        await viewModel.load()
        viewModel.updateWeight("20")
        let data = try Self.data(of: viewModel)
        #expect(data.canSave == false)
        #expect(data.hintText != nil)
    }

    @Test func outOfRangeWeightShowsHintAndBlocksSave() async throws {
        let viewModel = Self.makeViewModel(target: .new, database: try DatabaseFixtures.makeDatabase())
        await viewModel.load()
        viewModel.updateWeight("60")
        let data = try Self.data(of: viewModel)
        #expect(data.canSave == false)
        #expect(data.hintText != nil)
    }

    @Test func ownWeightIsNotADuplicate() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let existing = try await Self.plate(kilograms: 20, in: database)
        let viewModel = Self.makeViewModel(target: .existing(id: existing.id), database: database)
        await viewModel.load()
        let loaded = try Self.data(of: viewModel)
        #expect(loaded.weightText == "20")
        #expect(loaded.isExisting)

        viewModel.selectColor(PlateColor(rgb: Self.customRGB))
        let data = try Self.data(of: viewModel)
        #expect(data.canSave)
        #expect(data.hintText == nil)

        #expect(await viewModel.save())
        let saved = try await Self.plate(kilograms: 20, in: database)
        #expect(saved.color == PlateColor(rgb: Self.customRGB))
    }

    @Test func deleteRemovesPlate() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let existing = try await Self.plate(kilograms: 1.25, in: database)
        let viewModel = Self.makeViewModel(target: .existing(id: existing.id), database: database)
        await viewModel.load()
        #expect(await viewModel.delete())
        let plates = try await PlateRepositoryImpl(database: database).plates()
        #expect(!plates.contains(existing))
    }
}
