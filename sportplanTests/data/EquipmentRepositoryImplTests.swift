import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

struct EquipmentRepositoryImplTests {
    private static func makeEquipment(name: String, kind: EquipmentKind) -> Equipment {
        return Equipment(
            id: UUID(),
            name: name,
            kind: kind,
            baseWeight: .zero,
            weightStep: Weight(kilograms: 2.5),
            isArchived: false,
            createdAt: DatabaseFixtures.referenceDate
        )
    }

    @Test func observationFollowsSaveAndArchive() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = EquipmentRepositoryImpl(database: database)
        let equipment = DatabaseFixtures.makeEquipment()
        var iterator = repository.observeActive().makeAsyncIterator()

        let initial = try await iterator.next()
        #expect(initial == [])

        try await repository.save(equipment)
        let afterSave = try await iterator.next()
        #expect(afterSave == [equipment])

        try await repository.archive(id: equipment.id)
        let afterArchive = try await iterator.next()
        #expect(afterArchive == [])
    }

    @Test func ordersByKindThenName() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = EquipmentRepositoryImpl(database: database)
        let dumbbells = Self.makeEquipment(name: "Гантели", kind: .dumbbell)
        let smith = Self.makeEquipment(name: "Смит", kind: .barbell)
        let ezBar = Self.makeEquipment(name: "EZ-гриф", kind: .barbell)
        for item in [dumbbells, smith, ezBar] {
            try await repository.save(item)
        }
        var iterator = repository.observeActive().makeAsyncIterator()
        let names = try await iterator.next()?.map(\.name)
        #expect(names == ["EZ-гриф", "Смит", "Гантели"])
    }

    @Test func updatesExistingEquipment() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = EquipmentRepositoryImpl(database: database)
        var equipment = DatabaseFixtures.makeEquipment()
        try await repository.save(equipment)
        equipment.name = "Гриф 15 кг"
        try await repository.save(equipment)
        let fetched = try await repository.equipment(id: equipment.id)
        #expect(fetched == equipment)
    }

    @Test func countsExercisesUsingEquipment() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = EquipmentRepositoryImpl(database: database)
        let equipment = DatabaseFixtures.makeEquipment()
        let other = Self.makeEquipment(name: "Гантели", kind: .dumbbell)
        try await database.writer.write { db in
            try EquipmentRecord(equipment).insert(db)
            try EquipmentRecord(other).insert(db)
            try ExerciseRecord(DatabaseFixtures.makeExercise(load: .equipment(id: equipment.id))).insert(db)
            try ExerciseRecord(DatabaseFixtures.makeExercise(load: .equipment(id: equipment.id))).insert(db)
            try ExerciseRecord(DatabaseFixtures.makeExercise(load: .bodyweight)).insert(db)
        }
        #expect(try await repository.exerciseCount(usingEquipmentId: equipment.id) == 2)
        #expect(try await repository.exerciseCount(usingEquipmentId: other.id) == 0)
    }
}
