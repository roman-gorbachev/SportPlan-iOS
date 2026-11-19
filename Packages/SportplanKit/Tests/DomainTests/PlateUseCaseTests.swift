import Domain
import Foundation
import Testing

struct PlateUseCaseTests {
    private static func makePlate(kilograms: Double, color: PlatePaletteColor = .red) -> Plate {
        return Plate(id: UUID(), weight: Weight(kilograms: kilograms), color: color.color)
    }

    @Test func createsPlate() async throws {
        let repository = FakePlateRepository()
        let draft = PlateDraft(weight: Weight(kilograms: 0.5), color: PlatePaletteColor.black.color)
        let saved = try await SavePlateUseCase(repository: repository).execute(draft: draft, existingId: nil)
        #expect(saved.weight == Weight(kilograms: 0.5))
        #expect(saved.color == PlatePaletteColor.black.color)
        #expect(repository.stored == [saved])
    }

    @Test func updatesPlateKeepingItsWeight() async throws {
        let existing = Self.makePlate(kilograms: 20, color: .blue)
        let repository = FakePlateRepository(plates: [existing])
        let draft = PlateDraft(weight: existing.weight, color: PlatePaletteColor.black.color)
        let saved = try await SavePlateUseCase(repository: repository).execute(draft: draft, existingId: existing.id)
        #expect(saved.id == existing.id)
        #expect(repository.stored == [saved])
    }

    @Test func rejectsWeightOfAnotherPlate() async {
        let first = Self.makePlate(kilograms: 20)
        let second = Self.makePlate(kilograms: 10)
        let repository = FakePlateRepository(plates: [first, second])
        let draft = PlateDraft(weight: first.weight, color: second.color)
        await #expect(throws: PlateError.invalidDraft([.duplicateWeight])) {
            _ = try await SavePlateUseCase(repository: repository).execute(draft: draft, existingId: second.id)
        }
        #expect(repository.stored == [first, second])
    }

    @Test func rejectsOutOfRangeWeight() async {
        let repository = FakePlateRepository()
        let draft = PlateDraft(weight: Plate.maximumWeight + Weight(grams: 1), color: PlatePaletteColor.red.color)
        await #expect(throws: PlateError.invalidDraft([.weightOutOfRange])) {
            _ = try await SavePlateUseCase(repository: repository).execute(draft: draft, existingId: nil)
        }
    }

    @Test func savingMissingPlateFails() async {
        let repository = FakePlateRepository()
        let draft = PlateDraft(weight: Weight(kilograms: 5), color: PlatePaletteColor.white.color)
        await #expect(throws: PlateError.notFound) {
            _ = try await SavePlateUseCase(repository: repository).execute(draft: draft, existingId: UUID())
        }
    }

    @Test func editorSnapshotExcludesOwnWeight() async throws {
        let edited = Self.makePlate(kilograms: 20)
        let other = Self.makePlate(kilograms: 10)
        let repository = FakePlateRepository(plates: [edited, other])
        let snapshot = try await LoadPlateEditorUseCase(repository: repository).execute(id: edited.id)
        #expect(snapshot.plate == edited)
        #expect(snapshot.takenWeights == [other.weight])
    }

    @Test func newPlateSnapshotTakesAllWeights() async throws {
        let plates = [Self.makePlate(kilograms: 20), Self.makePlate(kilograms: 10)]
        let repository = FakePlateRepository(plates: plates)
        let snapshot = try await LoadPlateEditorUseCase(repository: repository).execute(id: nil)
        #expect(snapshot.plate == nil)
        #expect(snapshot.takenWeights == Set(plates.map(\.weight)))
    }

    @Test func deletesPlate() async throws {
        let kept = Self.makePlate(kilograms: 20)
        let removed = Self.makePlate(kilograms: 10)
        let repository = FakePlateRepository(plates: [kept, removed])
        try await DeletePlateUseCase(repository: repository).execute(id: removed.id)
        #expect(repository.stored == [kept])
    }

    @Test func resetReplacesSetWithStandard() async throws {
        let repository = FakePlateRepository(plates: [Self.makePlate(kilograms: 0.5, color: .black)])
        try await ResetPlatesToStandardUseCase(repository: repository).execute()
        let weights = repository.stored.map(\.weight)
        #expect(weights == StandardPlates.makeIWFSet().map(\.weight))
    }
}
