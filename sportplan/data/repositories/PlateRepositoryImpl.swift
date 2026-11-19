import Domain
import Foundation
import GRDB

nonisolated final class PlateRepositoryImpl: PlateRepository {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    func observeAll() -> AsyncThrowingStream<[Plate], any Error> {
        let observation = ValueObservation.tracking { db in
            return try Self.fetchPlates(db)
        }
        let reader = database.reader
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await plates in observation.values(in: reader) {
                        continuation.yield(plates)
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

    func plates() async throws -> [Plate] {
        return try await database.reader.read { db in
            return try Self.fetchPlates(db)
        }
    }

    func save(_ plate: Plate) async throws {
        try await database.writer.write { db in
            try PlateRecord(plate).save(db)
        }
    }

    func delete(id: UUID) async throws {
        try await database.writer.write { db in
            _ = try PlateRecord
                .filter(Column("id") == id.databaseText)
                .deleteAll(db)
        }
    }

    func replaceAll(with plates: [Plate]) async throws {
        try await database.writer.write { db in
            _ = try PlateRecord.deleteAll(db)
            for plate in plates {
                try PlateRecord(plate).insert(db)
            }
        }
    }

    private static func fetchPlates(_ db: Database) throws -> [Plate] {
        return try PlateRecord
            .order(Column("weight_g").desc)
            .fetchAll(db)
            .map { record in
                return try record.toDomainModel()
            }
    }
}
