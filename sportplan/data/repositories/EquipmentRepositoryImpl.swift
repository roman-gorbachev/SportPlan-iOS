import Domain
import Foundation
import GRDB

nonisolated final class EquipmentRepositoryImpl: EquipmentRepository {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    func observeActive() -> AsyncThrowingStream<[Equipment], any Error> {
        let observation = ValueObservation.tracking { db in
            return try EquipmentRecord
                .filter(Column("is_archived") == false)
                .fetchAll(db)
        }
        let reader = database.reader
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await records in observation.values(in: reader) {
                        let equipment = try records.map { record in
                            return try record.toDomainModel()
                        }
                        continuation.yield(equipment.sorted(by: Self.isOrderedBefore))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func equipment(id: UUID) async throws -> Equipment? {
        return try await database.reader.read { db in
            return try EquipmentRecord.fetchOne(db, key: id)?.toDomainModel()
        }
    }

    func save(_ equipment: Equipment) async throws {
        try await database.writer.write { db in
            try EquipmentRecord(equipment).save(db)
        }
    }

    func archive(id: UUID) async throws {
        try await database.writer.write { db in
            _ = try EquipmentRecord
                .filter(Column("id") == id.databaseText)
                .updateAll(db, Column("is_archived").set(to: true))
        }
    }

    func exerciseCount(usingEquipmentId id: UUID) async throws -> Int {
        return try await database.reader.read { db in
            return try ExerciseRecord
                .filter(Column("equipment_id") == id.databaseText)
                .fetchCount(db)
        }
    }

    private static func isOrderedBefore(_ lhs: Equipment, _ rhs: Equipment) -> Bool {
        let lhsKind = EquipmentKind.allCases.firstIndex(of: lhs.kind) ?? 0
        let rhsKind = EquipmentKind.allCases.firstIndex(of: rhs.kind) ?? 0
        guard lhsKind == rhsKind else {
            return lhsKind < rhsKind
        }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}
