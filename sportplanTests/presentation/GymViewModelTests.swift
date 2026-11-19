import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

@MainActor
struct GymViewModelTests {
    private static let customRGB = 0x123456
    private static let standardPlateCount = 7
    private static let pollInterval = Duration.milliseconds(10)
    private static let pollAttempts = 300

    private static func makeViewModel(database: AppDatabase) -> GymViewModel {
        let plates = PlateRepositoryImpl(database: database)
        return GymViewModel(
            observeGymEquipment: ObserveGymEquipmentUseCase(repository: EquipmentRepositoryImpl(database: database)),
            observePlates: ObservePlatesUseCase(repository: plates),
            resetPlatesToStandard: ResetPlatesToStandardUseCase(repository: plates)
        )
    }

    private static func waitForPlates(_ viewModel: GymViewModel, count: Int) async throws -> GymUiData {
        for _ in 0..<pollAttempts {
            if case let .success(data) = viewModel.gymUiState, data.plates.count == count {
                return data
            }
            try await Task.sleep(for: pollInterval)
        }
        throw PlateError.notFound
    }

    @Test func platesShowPaletteOrCustomColorNames() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = PlateRepositoryImpl(database: database)
        try await repository.replaceAll(with: [
            Plate(id: UUID(), weight: Weight(kilograms: 20), color: PlatePaletteColor.steel.color),
            Plate(id: UUID(), weight: Weight(kilograms: 10), color: PlateColor(rgb: Self.customRGB)),
        ])
        let viewModel = Self.makeViewModel(database: database)
        let task = Task {
            await viewModel.observe()
        }
        defer {
            task.cancel()
        }
        let data = try await Self.waitForPlates(viewModel, count: 2)
        #expect(data.plates.map(\.colorText) == [
            String(localized: "plate.color.steel").localizedLowercase,
            String(localized: "plate.color.customName").localizedLowercase,
        ])
    }

    @Test func resetRestoresStandardSet() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        try await PlateRepositoryImpl(database: database).replaceAll(with: [])
        let viewModel = Self.makeViewModel(database: database)
        let task = Task {
            await viewModel.observe()
        }
        defer {
            task.cancel()
        }
        _ = try await Self.waitForPlates(viewModel, count: 0)
        await viewModel.resetPlates()
        let data = try await Self.waitForPlates(viewModel, count: Self.standardPlateCount)
        #expect(data.isShowingResetError == false)
    }
}
