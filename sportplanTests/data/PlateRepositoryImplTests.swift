import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

struct PlateRepositoryImplTests {
    private static let standardKilograms: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    private static func makePlate(kilograms: Double, color: PlatePaletteColor = .black) -> Plate {
        return Plate(id: UUID(), weight: Weight(kilograms: kilograms), color: color.color)
    }

    @Test func platesAreListedFromTheHeaviest() async throws {
        let repository = PlateRepositoryImpl(database: try DatabaseFixtures.makeDatabase())
        let plates = try await repository.plates()
        #expect(plates.map(\.weight.kilograms) == Self.standardKilograms)
    }

    @Test func observationFollowsSaveUpdateAndDelete() async throws {
        let repository = PlateRepositoryImpl(database: try DatabaseFixtures.makeDatabase())
        try await repository.replaceAll(with: [])
        var iterator = repository.observeAll().makeAsyncIterator()
        let initial = try await iterator.next()
        #expect(initial == [])

        var plate = Self.makePlate(kilograms: 0.5)
        try await repository.save(plate)
        let afterSave = try await iterator.next()
        #expect(afterSave == [plate])

        plate.color = PlatePaletteColor.yellow.color
        try await repository.save(plate)
        let afterUpdate = try await iterator.next()
        #expect(afterUpdate == [plate])

        try await repository.delete(id: plate.id)
        let afterDelete = try await iterator.next()
        #expect(afterDelete == [])
    }

    @Test func duplicateWeightIsRejected() async throws {
        let repository = PlateRepositoryImpl(database: try DatabaseFixtures.makeDatabase())
        await #expect(throws: DatabaseError.self) {
            try await repository.save(Self.makePlate(kilograms: 20))
        }
    }

    @Test func replaceAllSwapsTheWholeSet() async throws {
        let repository = PlateRepositoryImpl(database: try DatabaseFixtures.makeDatabase())
        let custom = [Self.makePlate(kilograms: 0.5), Self.makePlate(kilograms: 7.5)]
        try await repository.replaceAll(with: custom)
        let replaced = try await repository.plates()
        #expect(replaced == custom.reversed())

        try await repository.replaceAll(with: StandardPlates.makeIWFSet())
        let restored = try await repository.plates()
        #expect(restored.map(\.weight.kilograms) == Self.standardKilograms)
    }
}
