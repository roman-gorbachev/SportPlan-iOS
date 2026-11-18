import Domain
import Foundation
import GRDB

nonisolated final class PlateRepositoryImpl: PlateRepository {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    func plates() async throws -> [Plate] {
        return try await database.reader.read { db in
            return try PlateRecord
                .order(Column("weight_g").desc)
                .fetchAll(db)
                .map { record in
                    return try record.toDomainModel()
                }
        }
    }
}
