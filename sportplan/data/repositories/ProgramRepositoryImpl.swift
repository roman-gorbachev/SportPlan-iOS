import Domain
import Foundation
import GRDB

nonisolated final class ProgramRepositoryImpl: ProgramRepository {
    private static let firstPosition = 0

    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    func observePrograms() -> AsyncThrowingStream<[ProgramSummary], any Error> {
        let observation = ValueObservation.tracking { db in
            return try Self.fetchSummaries(db)
        }
        return Self.stream(of: observation, in: database.reader)
    }

    func observeDay(id: UUID) -> AsyncThrowingStream<ProgramDayDetail?, any Error> {
        let observation = ValueObservation.tracking { db in
            return try Self.fetchDayDetail(db, id: id)
        }
        return Self.stream(of: observation, in: database.reader)
    }

    func createProgram(_ program: Program, firstDay: ProgramDay) async throws -> Program {
        return try await database.writer.write { db in
            var storedProgram = program
            storedProgram.position = try Self.nextPosition(db, sql: "SELECT MAX(position) FROM program", arguments: [])
            try ProgramRecord(storedProgram).insert(db)
            var storedDay = firstDay
            storedDay.position = Self.firstPosition
            try ProgramDayRecord(storedDay).insert(db)
            return storedProgram
        }
    }

    func renameProgram(id: UUID, name: String) async throws {
        try await database.writer.write { db in
            let updated = try ProgramRecord
                .filter(Column("id") == id.databaseText)
                .updateAll(db, Column("name").set(to: name))
            guard updated > 0 else {
                throw ProgramError.notFound
            }
        }
    }

    func deleteProgram(id: UUID) async throws {
        try await database.writer.write { db in
            _ = try ProgramRecord.filter(Column("id") == id.databaseText).deleteAll(db)
        }
    }

    func addDay(_ day: ProgramDay) async throws -> ProgramDay {
        return try await database.writer.write { db in
            let programExists = try ProgramRecord.filter(Column("id") == day.programId.databaseText).fetchCount(db) > 0
            guard programExists else {
                throw ProgramError.notFound
            }
            var storedDay = day
            storedDay.position = try Self.nextPosition(
                db,
                sql: "SELECT MAX(position) FROM program_day WHERE program_id = ?",
                arguments: [day.programId.databaseText]
            )
            try ProgramDayRecord(storedDay).insert(db)
            return storedDay
        }
    }

    func updateDay(id: UUID, name: String, label: String?) async throws {
        try await database.writer.write { db in
            let updated = try ProgramDayRecord
                .filter(Column("id") == id.databaseText)
                .updateAll(db, Column("name").set(to: name), Column("label").set(to: label))
            guard updated > 0 else {
                throw ProgramError.notFound
            }
        }
    }

    func deleteDay(id: UUID) async throws {
        try await database.writer.write { db in
            _ = try ProgramDayRecord.filter(Column("id") == id.databaseText).deleteAll(db)
        }
    }

    func plannedExercise(id: UUID) async throws -> PlannedExercise? {
        return try await database.reader.read { db in
            return try PlannedExerciseRecord
                .filter(Column("id") == id.databaseText)
                .fetchOne(db)?
                .toDomainModel()
        }
    }

    func addPlannedExercise(_ plannedExercise: PlannedExercise) async throws -> PlannedExercise {
        return try await database.writer.write { db in
            let dayId = plannedExercise.programDayId.databaseText
            let dayExists = try ProgramDayRecord.filter(Column("id") == dayId).fetchCount(db) > 0
            guard dayExists else {
                throw ProgramError.notFound
            }
            let isAlreadyInDay = try PlannedExerciseRecord
                .filter(Column("program_day_id") == dayId)
                .filter(Column("exercise_id") == plannedExercise.exerciseId.databaseText)
                .fetchCount(db) > 0
            guard !isAlreadyInDay else {
                throw ProgramError.exerciseAlreadyInDay
            }
            var stored = plannedExercise
            stored.position = try Self.nextPosition(
                db,
                sql: "SELECT MAX(position) FROM planned_exercise WHERE program_day_id = ?",
                arguments: [dayId]
            )
            try PlannedExerciseRecord(stored).insert(db)
            return stored
        }
    }

    func updateTargets(plannedExerciseId: UUID, targets: PlannedExerciseTargets) async throws {
        try await database.writer.write { db in
            let updated = try PlannedExerciseRecord
                .filter(Column("id") == plannedExerciseId.databaseText)
                .updateAll(
                    db,
                    Column("target_sets").set(to: targets.sets),
                    Column("target_reps_min").set(to: targets.reps?.min),
                    Column("target_reps_max").set(to: targets.reps?.max),
                    Column("rest_sec").set(to: targets.restSeconds)
                )
            guard updated > 0 else {
                throw ProgramError.notFound
            }
        }
    }

    func removePlannedExercise(id: UUID) async throws {
        try await database.writer.write { db in
            _ = try PlannedExerciseRecord.filter(Column("id") == id.databaseText).deleteAll(db)
        }
    }

    func reorderPlannedExercises(dayId: UUID, orderedIds: [UUID]) async throws {
        try await database.writer.write { db in
            for (position, id) in orderedIds.enumerated() {
                _ = try PlannedExerciseRecord
                    .filter(Column("id") == id.databaseText)
                    .filter(Column("program_day_id") == dayId.databaseText)
                    .updateAll(db, Column("position").set(to: position))
            }
        }
    }

    private static func nextPosition(_ db: Database, sql: String, arguments: StatementArguments) throws -> Int {
        guard let maximum = try Int.fetchOne(db, sql: sql, arguments: arguments) else {
            return firstPosition
        }
        return maximum + 1
    }

    private static func fetchSummaries(_ db: Database) throws -> [ProgramSummary] {
        let programs = try ProgramRecord.order(Column("position"), Column("created_at")).fetchAll(db)
        let days = try ProgramDayRecord.order(Column("position")).fetchAll(db)
        let countRows = try Row.fetchAll(
            db,
            sql: "SELECT program_day_id, COUNT(*) AS exercise_count FROM planned_exercise GROUP BY program_day_id"
        )
        let countsByDayId = Dictionary(uniqueKeysWithValues: countRows.map { row in
            let dayId: String = row["program_day_id"]
            let count: Int = row["exercise_count"]
            return (dayId, count)
        })
        let daysByProgramId = Dictionary(grouping: days) { day in
            return day.programId
        }
        return programs.map { program in
            let summaries = daysByProgramId[program.id, default: []].map { day in
                return ProgramDaySummary(
                    day: day.toDomainModel(),
                    exerciseCount: countsByDayId[day.id.databaseText, default: 0]
                )
            }
            return ProgramSummary(program: program.toDomainModel(), days: summaries)
        }
    }

    private static func fetchDayDetail(_ db: Database, id: UUID) throws -> ProgramDayDetail? {
        guard
            let day = try ProgramDayRecord.filter(Column("id") == id.databaseText).fetchOne(db),
            let program = try ProgramRecord.filter(Column("id") == day.programId.databaseText).fetchOne(db)
        else {
            return nil
        }
        let planned = try PlannedExerciseRecord
            .filter(Column("program_day_id") == id.databaseText)
            .order(Column("position"))
            .fetchAll(db)
        let exerciseIds = planned.map { record in
            return record.exerciseId.databaseText
        }
        let exercises = try ExerciseRecord.filter(exerciseIds.contains(Column("id"))).fetchAll(db)
        let equipmentIds = exercises.compactMap { record in
            return record.equipmentId?.databaseText
        }
        let equipment = try EquipmentRecord.filter(equipmentIds.contains(Column("id"))).fetchAll(db)
        let equipmentById = Dictionary(uniqueKeysWithValues: try equipment.map { record in
            return (record.id, try record.toDomainModel())
        })
        let exercisesById = Dictionary(uniqueKeysWithValues: try exercises.map { record in
            let exercise = try record.toDomainModel()
            let exerciseEquipment = record.equipmentId.flatMap { equipmentId in
                return equipmentById[equipmentId]
            }
            return (record.id, LibraryExercise(exercise: exercise, equipment: exerciseEquipment))
        })
        let items = try planned.compactMap { record -> PlannedExerciseItem? in
            guard let exercise = exercisesById[record.exerciseId] else {
                return nil
            }
            return PlannedExerciseItem(plannedExercise: try record.toDomainModel(), exercise: exercise)
        }
        return ProgramDayDetail(day: day.toDomainModel(), programName: program.name, exercises: items)
    }

    private static func stream<Value: Sendable>(
        of observation: ValueObservation<ValueReducers.Fetch<Value>>,
        in reader: any DatabaseReader
    ) -> AsyncThrowingStream<Value, any Error> {
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await value in observation.values(in: reader) {
                        continuation.yield(value)
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
}
