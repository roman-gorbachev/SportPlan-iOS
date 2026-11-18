import Domain
import Foundation
import GRDB

nonisolated final class ExerciseRepositoryImpl: ExerciseRepository {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    func observeLibrary() -> AsyncThrowingStream<[LibraryExercise], any Error> {
        let observation = ValueObservation.tracking { db in
            let exercises = try ExerciseRecord
                .filter(Column("is_archived") == false)
                .fetchAll(db)
            let equipment = try EquipmentRecord.fetchAll(db)
            return (exercises, equipment)
        }
        let reader = database.reader
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await (exerciseRecords, equipmentRecords) in observation.values(in: reader) {
                        continuation.yield(try Self.makeLibrary(exerciseRecords: exerciseRecords, equipmentRecords: equipmentRecords))
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

    func exercise(id: UUID) async throws -> Exercise? {
        return try await database.reader.read { db in
            return try ExerciseRecord
                .filter(Column("id") == id.databaseText)
                .fetchOne(db)?
                .toDomainModel()
        }
    }

    func create(_ exercise: Exercise) async throws {
        try await database.writer.write { db in
            try ExerciseRecord(exercise).insert(db)
        }
    }

    func programDayCount(usingExerciseId id: UUID) async throws -> Int {
        return try await database.reader.read { db in
            return try Int.fetchOne(
                db,
                sql: "SELECT COUNT(DISTINCT program_day_id) FROM planned_exercise WHERE exercise_id = ?",
                arguments: [id.databaseText]
            ) ?? 0
        }
    }

    func archive(id: UUID) async throws {
        try await database.writer.write { db in
            _ = try ExerciseRecord
                .filter(Column("id") == id.databaseText)
                .updateAll(db, Column("is_archived").set(to: true))
            _ = try PlannedExerciseRecord
                .filter(Column("exercise_id") == id.databaseText)
                .deleteAll(db)
        }
    }

    private static func makeLibrary(
        exerciseRecords: [ExerciseRecord],
        equipmentRecords: [EquipmentRecord]
    ) throws -> [LibraryExercise] {
        let equipmentById = Dictionary(uniqueKeysWithValues: try equipmentRecords.map { record in
            return (record.id, try record.toDomainModel())
        })
        return try exerciseRecords.map { record in
            let exercise = try record.toDomainModel()
            let equipment = record.equipmentId.flatMap { id in
                return equipmentById[id]
            }
            return LibraryExercise(exercise: exercise, equipment: equipment)
        }
    }
}
