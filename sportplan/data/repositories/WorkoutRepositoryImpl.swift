import Domain
import Foundation
import GRDB

nonisolated final class WorkoutRepositoryImpl: WorkoutRepository {
    private static let firstPosition = 0

    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    func observeActive() -> AsyncThrowingStream<ActiveWorkout?, any Error> {
        let observation = ValueObservation.tracking { db in
            return try Self.fetchActive(db)
        }
        return database.stream(of: observation)
    }

    func activeWorkout() async throws -> ActiveWorkout? {
        return try await database.reader.read { db in
            return try Self.fetchActive(db)
        }
    }

    func start(_ workout: Workout, exercises: [WorkoutExercise], sets: [SetEntry]) async throws {
        do {
            try await database.writer.write { db in
                try WorkoutRecord(workout).insert(db)
                for exercise in exercises {
                    try WorkoutExerciseRecord(exercise).insert(db)
                }
                for entry in sets {
                    try SetEntryRecord(entry).insert(db)
                }
            }
        } catch let error as DatabaseError where error.extendedResultCode == .SQLITE_CONSTRAINT_UNIQUE {
            throw WorkoutError.alreadyActive
        }
    }

    func addExercise(_ workoutExercise: WorkoutExercise, sets: [SetEntry]) async throws {
        try await database.writer.write { db in
            let workoutId = workoutExercise.workoutId.databaseText
            let isActive = try WorkoutRecord
                .filter(Column("id") == workoutId)
                .filter(Column("finished_at") == nil)
                .fetchCount(db) > 0
            guard isActive else {
                throw WorkoutError.noActiveWorkout
            }
            let isAlreadyInWorkout = try WorkoutExerciseRecord
                .filter(Column("workout_id") == workoutId)
                .filter(Column("exercise_id") == workoutExercise.exerciseId.databaseText)
                .fetchCount(db) > 0
            guard !isAlreadyInWorkout else {
                throw WorkoutError.exerciseAlreadyInWorkout
            }
            var stored = workoutExercise
            stored.position = try Self.nextPosition(
                db,
                sql: "SELECT MAX(position) FROM workout_exercise WHERE workout_id = ?",
                arguments: [workoutId]
            )
            try WorkoutExerciseRecord(stored).insert(db)
            for entry in sets {
                try SetEntryRecord(entry).insert(db)
            }
        }
    }

    func addSet(_ entry: SetEntry) async throws {
        try await database.writer.write { db in
            try db.execute(
                sql: "UPDATE set_entry SET position = position + 1 WHERE workout_exercise_id = ? AND position >= ?",
                arguments: [entry.workoutExerciseId.databaseText, entry.position]
            )
            try SetEntryRecord(entry).insert(db)
        }
    }

    func updateSet(_ entry: SetEntry) async throws {
        try await database.writer.write { db in
            let updated = try SetEntryRecord
                .filter(Column("id") == entry.id.databaseText)
                .updateAll(
                    db,
                    Column("weight_g").set(to: entry.weight.grams),
                    Column("reps").set(to: entry.reps),
                    Column("duration_sec").set(to: entry.durationSeconds),
                    Column("started_at").set(to: entry.startedAt),
                    Column("completed_at").set(to: entry.completedAt)
                )
            guard updated > 0 else {
                throw WorkoutError.notFound
            }
        }
    }

    func removeSet(id: UUID) async throws {
        try await database.writer.write { db in
            _ = try SetEntryRecord.filter(Column("id") == id.databaseText).deleteAll(db)
        }
    }

    func updateNote(workoutId: UUID, note: String?) async throws {
        try await database.writer.write { db in
            let updated = try WorkoutRecord
                .filter(Column("id") == workoutId.databaseText)
                .updateAll(db, Column("note").set(to: note))
            guard updated > 0 else {
                throw WorkoutError.notFound
            }
        }
    }

    func updateRest(workoutId: UUID, rest: RestPeriod?) async throws {
        try await database.writer.write { db in
            let updated = try WorkoutRecord
                .filter(Column("id") == workoutId.databaseText)
                .filter(Column("finished_at") == nil)
                .updateAll(
                    db,
                    Column("rest_started_at").set(to: rest?.startedAt),
                    Column("rest_ends_at").set(to: rest?.endsAt)
                )
            guard updated > 0 else {
                throw WorkoutError.noActiveWorkout
            }
        }
    }

    func finish(workoutId: UUID, at date: Date) async throws {
        try await database.writer.write { db in
            let id = workoutId.databaseText
            try db.execute(
                sql: """
                    DELETE FROM set_entry
                    WHERE completed_at IS NULL
                    AND workout_exercise_id IN (SELECT id FROM workout_exercise WHERE workout_id = ?)
                    """,
                arguments: [id]
            )
            try db.execute(
                sql: """
                    DELETE FROM workout_exercise
                    WHERE workout_id = ?
                    AND NOT EXISTS (SELECT 1 FROM set_entry WHERE set_entry.workout_exercise_id = workout_exercise.id)
                    """,
                arguments: [id]
            )
            let updated = try WorkoutRecord
                .filter(Column("id") == id)
                .filter(Column("finished_at") == nil)
                .updateAll(
                    db,
                    Column("finished_at").set(to: date),
                    Column("rest_started_at").set(to: nil as Date?),
                    Column("rest_ends_at").set(to: nil as Date?)
                )
            guard updated > 0 else {
                throw WorkoutError.noActiveWorkout
            }
        }
    }

    func cancel(workoutId: UUID) async throws {
        try await database.writer.write { db in
            _ = try WorkoutRecord
                .filter(Column("id") == workoutId.databaseText)
                .filter(Column("finished_at") == nil)
                .deleteAll(db)
        }
    }

    func previousSets(exerciseId: UUID) async throws -> [SetEntry] {
        return try await database.reader.read { db in
            return try Self.fetchPreviousSets(db, exerciseId: exerciseId)
        }
    }

    private static func nextPosition(_ db: Database, sql: String, arguments: StatementArguments) throws -> Int {
        guard let maximum = try Int.fetchOne(db, sql: sql, arguments: arguments) else {
            return firstPosition
        }
        return maximum + 1
    }

    private static func fetchActive(_ db: Database) throws -> ActiveWorkout? {
        guard let record = try WorkoutRecord.filter(Column("finished_at") == nil).fetchOne(db) else {
            return nil
        }
        let workout = try record.toDomainModel()
        let programName = try record.programDayId.flatMap { dayId in
            return try String.fetchOne(
                db,
                sql: """
                    SELECT program.name FROM program_day
                    JOIN program ON program.id = program_day.program_id
                    WHERE program_day.id = ?
                    """,
                arguments: [dayId.databaseText]
            )
        }
        let workoutExercises = try WorkoutExerciseRecord
            .filter(Column("workout_id") == workout.id.databaseText)
            .order(Column("position"))
            .fetchAll(db)
        let libraryById = try fetchLibraryExercises(db, ids: workoutExercises.map(\.exerciseId))
        let setRecords = try SetEntryRecord
            .filter(workoutExercises.map(\.id.databaseText).contains(Column("workout_exercise_id")))
            .order(Column("position"))
            .fetchAll(db)
        let setsByExerciseId = Dictionary(grouping: setRecords.map { record in
            return record.toDomainModel()
        }) { entry in
            return entry.workoutExerciseId
        }
        let exercises = try workoutExercises.compactMap { record -> ActiveWorkoutExercise? in
            guard let exercise = libraryById[record.exerciseId] else {
                return nil
            }
            return ActiveWorkoutExercise(
                workoutExercise: try record.toDomainModel(),
                exercise: exercise,
                sets: setsByExerciseId[record.id, default: []],
                previousSets: try fetchPreviousSets(db, exerciseId: record.exerciseId)
            )
        }
        return ActiveWorkout(workout: workout, programName: programName, exercises: exercises)
    }

    private static func fetchLibraryExercises(_ db: Database, ids: [UUID]) throws -> [UUID: LibraryExercise] {
        let exercises = try ExerciseRecord.filter(ids.map(\.databaseText).contains(Column("id"))).fetchAll(db)
        let equipmentIds = exercises.compactMap { record in
            return record.equipmentId?.databaseText
        }
        let equipment = try EquipmentRecord.filter(equipmentIds.contains(Column("id"))).fetchAll(db)
        let equipmentById = Dictionary(uniqueKeysWithValues: try equipment.map { record in
            return (record.id, try record.toDomainModel())
        })
        return Dictionary(uniqueKeysWithValues: try exercises.map { record in
            let exerciseEquipment = record.equipmentId.flatMap { equipmentId in
                return equipmentById[equipmentId]
            }
            return (record.id, LibraryExercise(exercise: try record.toDomainModel(), equipment: exerciseEquipment))
        })
    }

    private static func fetchPreviousSets(_ db: Database, exerciseId: UUID) throws -> [SetEntry] {
        return try SetEntryRecord.fetchAll(
            db,
            sql: """
                SELECT * FROM set_entry
                WHERE completed_at IS NOT NULL
                AND workout_exercise_id = (
                    SELECT workout_exercise.id FROM workout_exercise
                    JOIN workout ON workout.id = workout_exercise.workout_id
                    WHERE workout_exercise.exercise_id = ?
                    AND workout.finished_at IS NOT NULL
                    AND EXISTS (
                        SELECT 1 FROM set_entry AS completed
                        WHERE completed.workout_exercise_id = workout_exercise.id
                        AND completed.completed_at IS NOT NULL
                    )
                    ORDER BY workout.started_at DESC
                    LIMIT 1
                )
                ORDER BY position
                """,
            arguments: [exerciseId.databaseText]
        ).map { record in
            return record.toDomainModel()
        }
    }
}
