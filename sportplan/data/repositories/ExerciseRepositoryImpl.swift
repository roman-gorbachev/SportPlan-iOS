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

    func observeArchived() -> AsyncThrowingStream<[ArchivedExercise], any Error> {
        let observation = ValueObservation.tracking { db in
            let exercises = try ExerciseRecord
                .filter(Column("is_archived") == true)
                .fetchAll(db)
            let equipment = try EquipmentRecord.fetchAll(db)
            let countRows = try Row.fetchAll(db, sql: """
                SELECT workout_exercise.exercise_id AS exercise_id, COUNT(DISTINCT workout_exercise.workout_id) AS workout_count
                FROM workout_exercise
                JOIN workout ON workout.id = workout_exercise.workout_id
                JOIN exercise ON exercise.id = workout_exercise.exercise_id
                WHERE workout.finished_at IS NOT NULL AND exercise.is_archived = 1
                GROUP BY workout_exercise.exercise_id
                """)
            let workoutCounts = Dictionary(uniqueKeysWithValues: countRows.map { row in
                let exerciseId: String = row["exercise_id"]
                let workoutCount: Int = row["workout_count"]
                return (exerciseId, workoutCount)
            })
            let library = try Self.makeLibrary(exerciseRecords: exercises, equipmentRecords: equipment)
            return library.map { item in
                return ArchivedExercise(exercise: item, workoutCount: workoutCounts[item.id.databaseText] ?? 0)
            }
        }
        return database.stream(of: observation)
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

    func update(_ exercise: Exercise) async throws {
        try await database.writer.write { db in
            try ExerciseRecord(exercise).update(db)
        }
    }

    func hasCompletedSets(exerciseId: UUID) async throws -> Bool {
        return try await database.reader.read { db in
            return try Bool.fetchOne(
                db,
                sql: """
                    SELECT EXISTS (
                        SELECT 1 FROM set_entry
                        JOIN workout_exercise ON workout_exercise.id = set_entry.workout_exercise_id
                        WHERE workout_exercise.exercise_id = ? AND set_entry.completed_at IS NOT NULL
                    )
                    """,
                arguments: [exerciseId.databaseText]
            ) ?? false
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

    func restore(id: UUID) async throws {
        try await database.writer.write { db in
            _ = try ExerciseRecord
                .filter(Column("id") == id.databaseText)
                .updateAll(db, Column("is_archived").set(to: false))
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
