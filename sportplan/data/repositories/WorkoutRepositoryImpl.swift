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
            try Self.update(db, entry: entry)
        }
    }

    func updateSets(_ entries: [SetEntry]) async throws {
        try await database.writer.write { db in
            for entry in entries {
                try Self.update(db, entry: entry)
            }
        }
    }

    private static func update(_ db: Database, entry: SetEntry) throws {
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

    func previousWorkoutExercise(exerciseId: UUID) async throws -> WorkoutExercise? {
        return try await database.reader.read { db in
            return try Self.fetchPreviousWorkoutExercise(db, exerciseId: exerciseId)?.toDomainModel()
        }
    }

    func lastWorkoutDate(programDayId: UUID) async throws -> Date? {
        return try await database.reader.read { db in
            return try Date.fetchOne(
                db,
                sql: """
                    SELECT MAX(started_at) FROM workout
                    WHERE finished_at IS NOT NULL AND program_day_id = ?
                    """,
                arguments: [programDayId.databaseText]
            )
        }
    }

    func observeExerciseHistory(exerciseId: UUID) -> AsyncThrowingStream<ExerciseHistory?, any Error> {
        let observation = ValueObservation.tracking { db in
            return try Self.fetchExerciseHistory(db, exerciseId: exerciseId)
        }
        return database.stream(of: observation)
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
            let previous = try fetchPreviousWorkoutExercise(db, exerciseId: record.exerciseId)
            return ActiveWorkoutExercise(
                workoutExercise: try record.toDomainModel(),
                exercise: exercise,
                sets: setsByExerciseId[record.id, default: []],
                previousSets: try previous.map { previous in
                    return try fetchCompletedSets(db, workoutExerciseId: previous.id)
                } ?? [],
                previousWorkoutExercise: try previous?.toDomainModel(),
                recordBaseline: RecordBaseline(sets: try fetchFinishedWorkingSets(db, exerciseId: record.exerciseId))
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

    private static func fetchPreviousWorkoutExercise(_ db: Database, exerciseId: UUID) throws -> WorkoutExerciseRecord? {
        return try WorkoutExerciseRecord.fetchOne(
            db,
            sql: """
                SELECT workout_exercise.* FROM workout_exercise
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
                """,
            arguments: [exerciseId.databaseText]
        )
    }

    private static func fetchPreviousSets(_ db: Database, exerciseId: UUID) throws -> [SetEntry] {
        guard let previous = try fetchPreviousWorkoutExercise(db, exerciseId: exerciseId) else {
            return []
        }
        return try fetchCompletedSets(db, workoutExerciseId: previous.id)
    }

    private static func fetchCompletedSets(_ db: Database, workoutExerciseId: UUID) throws -> [SetEntry] {
        return try SetEntryRecord
            .filter(Column("workout_exercise_id") == workoutExerciseId.databaseText)
            .filter(Column("completed_at") != nil)
            .order(Column("position"))
            .fetchAll(db)
            .map { record in
                return record.toDomainModel()
            }
    }

    private static func fetchFinishedWorkingSets(_ db: Database, exerciseId: UUID) throws -> [SetEntry] {
        return try SetEntryRecord.fetchAll(
            db,
            sql: """
                SELECT set_entry.* FROM set_entry
                JOIN workout_exercise ON workout_exercise.id = set_entry.workout_exercise_id
                JOIN workout ON workout.id = workout_exercise.workout_id
                WHERE workout_exercise.exercise_id = ?
                AND workout.finished_at IS NOT NULL
                AND set_entry.completed_at IS NOT NULL
                AND set_entry.is_warmup = 0
                """,
            arguments: [exerciseId.databaseText]
        ).map { record in
            return record.toDomainModel()
        }
    }

    private static func fetchExerciseHistory(_ db: Database, exerciseId: UUID) throws -> ExerciseHistory? {
        guard let exercise = try fetchLibraryExercises(db, ids: [exerciseId])[exerciseId] else {
            return nil
        }
        let workoutExercises = try WorkoutExerciseRecord
            .filter(Column("exercise_id") == exerciseId.databaseText)
            .fetchAll(db)
        let workoutIdByItemId = Dictionary(uniqueKeysWithValues: workoutExercises.map { record in
            return (record.id, record.workoutId)
        })
        let sets = try SetEntryRecord
            .filter(workoutExercises.map(\.id.databaseText).contains(Column("workout_exercise_id")))
            .filter(Column("completed_at") != nil)
            .filter(Column("is_warmup") == false)
            .order(Column("position"))
            .fetchAll(db)
            .map { record in
                return record.toDomainModel()
            }
        let setsByWorkoutId = Dictionary(grouping: sets) { entry in
            return workoutIdByItemId[entry.workoutExerciseId]
        }
        let workouts = try WorkoutRecord
            .filter(setsByWorkoutId.keys.compactMap { workoutId in return workoutId?.databaseText }.contains(Column("id")))
            .order(Column("started_at").desc)
            .fetchAll(db)
        let sessions = workouts.map { workout in
            return ExerciseSession(
                workoutId: workout.id,
                date: workout.startedAt,
                sets: setsByWorkoutId[workout.id, default: []]
            )
        }
        return ExerciseHistory(exercise: exercise, sessions: sessions)
    }
}
