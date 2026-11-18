import Domain
import Foundation
import Testing

struct SaveEquipmentUseCaseTests {
    private static let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)

    private static func makeUseCase(_ repository: FakeEquipmentRepository) -> SaveEquipmentUseCase {
        return SaveEquipmentUseCase(repository: repository, now: { return referenceDate })
    }

    private static func makeEquipment(kind: EquipmentKind = .barbell) -> Equipment {
        return Equipment(
            id: UUID(),
            name: "Олимпийский гриф",
            kind: kind,
            baseWeight: Weight(kilograms: 20),
            weightStep: Weight(kilograms: 2.5),
            isArchived: false,
            createdAt: referenceDate
        )
    }

    @Test func createsEquipmentWithTrimmedName() async throws {
        let repository = FakeEquipmentRepository()
        let draft = EquipmentDraft(name: "  EZ-гриф ", kind: .barbell, baseWeight: Weight(kilograms: 10), weightStep: Weight(kilograms: 2.5))
        let saved = try await Self.makeUseCase(repository).execute(draft: draft, existingId: nil)
        #expect(saved.name == "EZ-гриф")
        #expect(saved.createdAt == Self.referenceDate)
        #expect(!saved.isArchived)
        #expect(repository.stored == [saved])
    }

    @Test func storesZeroBaseWeightForDumbbells() async throws {
        let repository = FakeEquipmentRepository()
        let draft = EquipmentDraft(name: "Гантели", kind: .dumbbell, baseWeight: Weight(kilograms: 20), weightStep: Weight(kilograms: 2))
        let saved = try await Self.makeUseCase(repository).execute(draft: draft, existingId: nil)
        #expect(saved.baseWeight == .zero)
    }

    @Test func rejectsInvalidDraft() async {
        let repository = FakeEquipmentRepository()
        let draft = EquipmentDraft(name: "", kind: .barbell, baseWeight: .zero, weightStep: Weight(kilograms: 2.5))
        await #expect(throws: EquipmentError.invalidDraft([.emptyName])) {
            _ = try await Self.makeUseCase(repository).execute(draft: draft, existingId: nil)
        }
        #expect(repository.stored.isEmpty)
    }

    @Test func refusesKindChangeWhenUsed() async {
        let existing = Self.makeEquipment()
        let repository = FakeEquipmentRepository(equipment: [existing], exerciseCounts: [existing.id: 2])
        var draft = EquipmentDraft(existing)
        draft.kind = .dumbbell
        await #expect(throws: EquipmentError.kindLocked) {
            _ = try await Self.makeUseCase(repository).execute(draft: draft, existingId: existing.id)
        }
    }

    @Test func allowsKindChangeWhenUnused() async throws {
        let existing = Self.makeEquipment()
        let repository = FakeEquipmentRepository(equipment: [existing])
        var draft = EquipmentDraft(existing)
        draft.kind = .plateLoadedMachine
        let saved = try await Self.makeUseCase(repository).execute(draft: draft, existingId: existing.id)
        #expect(saved.kind == .plateLoadedMachine)
        #expect(saved.id == existing.id)
        #expect(saved.createdAt == existing.createdAt)
    }

    @Test func allowsRenameWhenUsed() async throws {
        let existing = Self.makeEquipment()
        let repository = FakeEquipmentRepository(equipment: [existing], exerciseCounts: [existing.id: 3])
        var draft = EquipmentDraft(existing)
        draft.name = "Гриф 20 кг"
        draft.baseWeight = Weight(kilograms: 15)
        let saved = try await Self.makeUseCase(repository).execute(draft: draft, existingId: existing.id)
        #expect(saved.name == "Гриф 20 кг")
        #expect(saved.baseWeight == Weight(kilograms: 15))
    }

    @Test func failsForMissingEquipment() async {
        let repository = FakeEquipmentRepository()
        let draft = EquipmentDraft(Self.makeEquipment())
        await #expect(throws: EquipmentError.notFound) {
            _ = try await Self.makeUseCase(repository).execute(draft: draft, existingId: UUID())
        }
    }
}
