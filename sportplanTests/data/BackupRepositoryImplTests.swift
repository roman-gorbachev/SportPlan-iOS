import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

struct BackupRepositoryImplTests {
    private static let workoutLength: TimeInterval = 3_000
    private static let millisecondOffset: TimeInterval = 0.123

    private struct Seed {
        let database: AppDatabase
        let activeWorkoutId: UUID
    }

    private static func seed(_ database: AppDatabase) async throws -> Seed {
        let bar = DatabaseFixtures.makeEquipment()
        var archivedBar = DatabaseFixtures.makeEquipment()
        archivedBar.isArchived = true
        let bench = DatabaseFixtures.makeExercise(load: .equipment(id: bar.id))
        var archived = DatabaseFixtures.makeExercise(load: .bodyweight)
        archived.isArchived = true
        let program = DatabaseFixtures.makeProgram()
        let day = DatabaseFixtures.makeDay(programId: program.id)
        let planned = DatabaseFixtures.makePlannedExercise(dayId: day.id, exerciseId: bench.id)
        let template = DatabaseFixtures.makeWorkout(day: day, finishedAt: nil)
        let finished = Workout(
            id: template.id,
            programDay: template.programDay,
            startedAt: DatabaseFixtures.referenceDate.addingTimeInterval(millisecondOffset),
            finishedAt: DatabaseFixtures.referenceDate.addingTimeInterval(workoutLength),
            note: template.note,
            rest: nil
        )
        let active = DatabaseFixtures.makeWorkout(day: nil, finishedAt: nil)
        let finishedExercise = DatabaseFixtures.makeWorkoutExercise(workoutId: finished.id, exerciseId: bench.id)
        let activeExercise = DatabaseFixtures.makeWorkoutExercise(workoutId: active.id, exerciseId: archived.id)
        var warmup = DatabaseFixtures.makeSet(workoutExerciseId: finishedExercise.id)
        warmup.isWarmup = true
        var working = DatabaseFixtures.makeSet(workoutExerciseId: finishedExercise.id)
        working.position = 1
        let pending = SetEntry(
            id: UUID(),
            workoutExerciseId: activeExercise.id,
            position: 0,
            weight: .zero,
            reps: nil,
            durationSeconds: nil,
            isWarmup: false,
            startedAt: nil,
            completedAt: nil
        )
        let records: [any PersistableRecord & Sendable] = [
            EquipmentRecord(bar),
            EquipmentRecord(archivedBar),
            ExerciseRecord(bench),
            ExerciseRecord(archived),
            ProgramRecord(program),
            ProgramDayRecord(day),
            PlannedExerciseRecord(planned),
            WorkoutRecord(finished),
            WorkoutRecord(active),
            WorkoutExerciseRecord(finishedExercise),
            WorkoutExerciseRecord(activeExercise),
            SetEntryRecord(warmup),
            SetEntryRecord(working),
            SetEntryRecord(pending),
        ]
        try await database.writer.write { db in
            for record in records {
                try record.insert(db)
            }
        }
        return Seed(database: database, activeWorkoutId: active.id)
    }

    private static func write(_ contents: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        try contents.write(to: url)
        return url
    }

    private static func count(_ table: String, in database: AppDatabase) async throws -> Int {
        return try await database.reader.read { db in
            return try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(table)") ?? 0
        }
    }

    private static func jsonObject(_ contents: Data) throws -> [String: Any] {
        return try #require(try JSONSerialization.jsonObject(with: contents) as? [String: Any])
    }

    private static func data(_ object: [String: Any]) throws -> Data {
        return try JSONSerialization.data(withJSONObject: object)
    }

    @Test func exportImportExportGivesTheSameFile() async throws {
        let source = try await Self.seed(try DatabaseFixtures.makeDatabase())
        let exported = try await BackupRepositoryImpl(database: source.database).makeBackup(exportedAt: DatabaseFixtures.referenceDate)
        let target = try DatabaseFixtures.makeDatabase()
        let repository = BackupRepositoryImpl(database: target)
        try await repository.replaceAll(contents: exported)
        let reexported = try await repository.makeBackup(exportedAt: DatabaseFixtures.referenceDate)
        #expect(String(decoding: reexported, as: UTF8.self) == String(decoding: exported, as: UTF8.self))
        let workout = try await WorkoutRepositoryImpl(database: target).activeWorkout()
        #expect(workout?.workout.id == source.activeWorkoutId)
        #expect(workout?.workout.rest == nil)
    }

    @Test func fileHasTheVersionAndKeepsMilliseconds() async throws {
        let source = try await Self.seed(try DatabaseFixtures.makeDatabase())
        let exported = try await BackupRepositoryImpl(database: source.database).makeBackup(exportedAt: DatabaseFixtures.referenceDate)
        let text = String(decoding: exported, as: UTF8.self)
        #expect(text.contains("\"schemaVersion\" : 1"))
        #expect(text.contains("\"exportedAt\" : \"2027-01-15T08:00:00.000Z\""))
        #expect(text.contains("\"startedAt\" : \"2027-01-15T08:00:00.123Z\""))
        #expect(!text.contains("restEndsAt\" : \""))
    }

    @Test func replaceAllRemovesThePreviousData() async throws {
        let source = try DatabaseFixtures.makeDatabase()
        try await PlateRepositoryImpl(database: source).replaceAll(with: [])
        let exported = try await BackupRepositoryImpl(database: source).makeBackup(exportedAt: DatabaseFixtures.referenceDate)
        let target = try await Self.seed(try DatabaseFixtures.makeDatabase())
        try await BackupRepositoryImpl(database: target.database).replaceAll(contents: exported)
        for table in ["equipment", "plate", "exercise", "program", "program_day", "planned_exercise", "workout", "workout_exercise", "set_entry"] {
            #expect(try await Self.count(table, in: target.database) == 0)
        }
    }

    @Test func readingSummarizesTheFileWithoutChangingData() async throws {
        let source = try await Self.seed(try DatabaseFixtures.makeDatabase())
        let exported = try await BackupRepositoryImpl(database: source.database).makeBackup(exportedAt: DatabaseFixtures.referenceDate)
        let target = try DatabaseFixtures.makeDatabase()
        let candidate = try await BackupRepositoryImpl(database: target).readBackup(fileURL: try Self.write(exported))
        #expect(candidate.summary == BackupSummary(exportedAt: DatabaseFixtures.referenceDate, workoutCount: 1, exerciseCount: 2, programCount: 1))
        #expect(candidate.contents == exported)
        #expect(try await Self.count("workout", in: target) == 0)
        #expect(try await Self.count("plate", in: target) == StandardPlates.makeIWFSet().count)
    }

    @Test func newerVersionIsRejected() async throws {
        let source = try DatabaseFixtures.makeDatabase()
        let exported = try await BackupRepositoryImpl(database: source).makeBackup(exportedAt: DatabaseFixtures.referenceDate)
        var object = try Self.jsonObject(exported)
        object["schemaVersion"] = BackupFile.currentVersion + 1
        object["plates"] = nil
        let url = try Self.write(try Self.data(object))
        await #expect(throws: BackupError.newerVersion) {
            _ = try await BackupRepositoryImpl(database: source).readBackup(fileURL: url)
        }
    }

    @Test func malformedFileIsUnreadable() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = BackupRepositoryImpl(database: database)
        let garbage = try Self.write(Data("not json".utf8))
        let missingTables = try Self.write(try Self.data(["schemaVersion": BackupFile.currentVersion]))
        let missingFile = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        for url in [garbage, missingTables, missingFile] {
            await #expect(throws: BackupError.unreadable) {
                _ = try await repository.readBackup(fileURL: url)
            }
        }
    }

    @Test func brokenReferenceIsRejectedAndDataStays() async throws {
        let source = try await Self.seed(try DatabaseFixtures.makeDatabase())
        let repository = BackupRepositoryImpl(database: source.database)
        let exported = try await repository.makeBackup(exportedAt: DatabaseFixtures.referenceDate)
        var object = try Self.jsonObject(exported)
        var sets = try #require(object["sets"] as? [[String: Any]])
        sets[0]["workoutExerciseId"] = UUID().uuidString
        object["sets"] = sets
        let broken = try Self.data(object)
        await #expect(throws: BackupError.invalidData) {
            _ = try await repository.readBackup(fileURL: try Self.write(broken))
        }
        await #expect(throws: BackupError.invalidData) {
            try await repository.replaceAll(contents: broken)
        }
        let after = try await repository.makeBackup(exportedAt: DatabaseFixtures.referenceDate)
        #expect(after == exported)
    }
}
