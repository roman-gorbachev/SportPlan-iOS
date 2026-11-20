import Domain
import Foundation
import GRDB

nonisolated final class BackupRepositoryImpl: BackupRepository {
    private static let idColumn = Column("id")

    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    func makeBackup(exportedAt: Date) async throws -> Data {
        let file = try await database.reader.read { db in
            return try Self.fetchFile(db, exportedAt: exportedAt)
        }
        return try BackupCoding.makeEncoder().encode(file)
    }

    func readBackup(fileURL: URL) async throws -> BackupCandidate {
        let contents = try BackupFileReader.read(fileURL: fileURL)
        let file = try Self.decode(contents)
        try await database.writer.writeWithoutTransaction { db in
            try db.inTransaction {
                try Self.replace(db, with: file)
                return .rollback
            }
        }
        return BackupCandidate(summary: Self.summary(of: file), contents: contents)
    }

    func replaceAll(contents: Data) async throws {
        let file = try Self.decode(contents)
        try await database.writer.write { db in
            try Self.replace(db, with: file)
        }
    }

    private static func decode(_ contents: Data) throws -> BackupFile {
        let decoder = BackupCoding.makeDecoder()
        guard let header = try? decoder.decode(BackupFileHeader.self, from: contents) else {
            throw BackupError.unreadable
        }
        guard header.schemaVersion <= BackupFile.currentVersion else {
            throw BackupError.newerVersion
        }
        guard header.schemaVersion == BackupFile.currentVersion,
              let file = try? decoder.decode(BackupFile.self, from: contents) else {
            throw BackupError.unreadable
        }
        return file
    }

    private static func summary(of file: BackupFile) -> BackupSummary {
        return BackupSummary(
            exportedAt: file.exportedAt,
            workoutCount: file.workouts.filter { workout in
                return workout.finishedAt != nil
            }.count,
            exerciseCount: file.exercises.count,
            programCount: file.programs.count
        )
    }

    private static func fetchFile(_ db: Database, exportedAt: Date) throws -> BackupFile {
        let workouts = try BackupWorkout.order(idColumn).fetchAll(db).map { workout in
            var workout = workout
            workout.restStartedAt = nil
            workout.restEndsAt = nil
            return workout
        }
        return BackupFile(
            schemaVersion: BackupFile.currentVersion,
            exportedAt: exportedAt,
            equipment: try BackupEquipment.order(idColumn).fetchAll(db),
            plates: try BackupPlate.order(idColumn).fetchAll(db),
            exercises: try BackupExercise.order(idColumn).fetchAll(db),
            programs: try BackupProgram.order(idColumn).fetchAll(db),
            programDays: try BackupProgramDay.order(idColumn).fetchAll(db),
            plannedExercises: try BackupPlannedExercise.order(idColumn).fetchAll(db),
            workouts: workouts,
            workoutExercises: try BackupWorkoutExercise.order(idColumn).fetchAll(db),
            sets: try BackupSet.order(idColumn).fetchAll(db)
        )
    }

    private static func replace(_ db: Database, with file: BackupFile) throws {
        do {
            try deleteAll(db)
            try insert(file.equipment, db)
            try insert(file.plates, db)
            try insert(file.exercises, db)
            try insert(file.programs, db)
            try insert(file.programDays, db)
            try insert(file.plannedExercises, db)
            try insert(file.workouts, db)
            try insert(file.workoutExercises, db)
            try insert(file.sets, db)
        } catch is DatabaseError {
            throw BackupError.invalidData
        }
    }

    private static func deleteAll(_ db: Database) throws {
        _ = try BackupSet.deleteAll(db)
        _ = try BackupWorkoutExercise.deleteAll(db)
        _ = try BackupWorkout.deleteAll(db)
        _ = try BackupPlannedExercise.deleteAll(db)
        _ = try BackupProgramDay.deleteAll(db)
        _ = try BackupProgram.deleteAll(db)
        _ = try BackupExercise.deleteAll(db)
        _ = try BackupEquipment.deleteAll(db)
        _ = try BackupPlate.deleteAll(db)
    }

    private static func insert(_ rows: [some PersistableRecord], _ db: Database) throws {
        for row in rows {
            try row.insert(db)
        }
    }
}
