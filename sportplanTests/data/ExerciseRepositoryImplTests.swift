import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

struct ExerciseRepositoryImplTests {
    @Test func libraryFollowsCreateAndArchive() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = ExerciseRepositoryImpl(database: database)
        let equipment = DatabaseFixtures.makeEquipment()
        try await database.writer.write { db in
            try EquipmentRecord(equipment).insert(db)
        }
        let exercise = DatabaseFixtures.makeExercise(load: .equipment(id: equipment.id))
        var iterator = repository.observeLibrary().makeAsyncIterator()

        let initial = try await iterator.next()
        #expect(initial == [])

        try await repository.create(exercise)
        let afterCreate = try await iterator.next()
        #expect(afterCreate == [LibraryExercise(exercise: exercise, equipment: equipment)])

        try await repository.archive(id: exercise.id)
        let afterArchive = try await iterator.next()
        #expect(afterArchive == [])
    }

    @Test func libraryKeepsArchivedEquipment() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = ExerciseRepositoryImpl(database: database)
        var archivedEquipment = DatabaseFixtures.makeEquipment()
        archivedEquipment.isArchived = true
        let equipment = archivedEquipment
        let exercise = DatabaseFixtures.makeExercise(load: .equipment(id: equipment.id))
        try await database.writer.write { db in
            try EquipmentRecord(equipment).insert(db)
            try ExerciseRecord(exercise).insert(db)
        }
        var iterator = repository.observeLibrary().makeAsyncIterator()
        let library = try await iterator.next()
        #expect(library?.first?.equipment == equipment)
    }

    @Test func countsDistinctProgramDays() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = ExerciseRepositoryImpl(database: database)
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        let program = DatabaseFixtures.makeProgram()
        let firstDay = DatabaseFixtures.makeDay(programId: program.id)
        var laterDay = DatabaseFixtures.makeDay(programId: program.id)
        laterDay.position = 1
        let secondDay = laterDay
        try await database.writer.write { db in
            try ExerciseRecord(exercise).insert(db)
            try ProgramRecord(program).insert(db)
            try ProgramDayRecord(firstDay).insert(db)
            try ProgramDayRecord(secondDay).insert(db)
            try PlannedExerciseRecord(DatabaseFixtures.makePlannedExercise(dayId: firstDay.id, exerciseId: exercise.id)).insert(db)
            try PlannedExerciseRecord(DatabaseFixtures.makePlannedExercise(dayId: firstDay.id, exerciseId: exercise.id)).insert(db)
            try PlannedExerciseRecord(DatabaseFixtures.makePlannedExercise(dayId: secondDay.id, exerciseId: exercise.id)).insert(db)
        }
        let count = try await repository.programDayCount(usingExerciseId: exercise.id)
        #expect(count == 2)
    }

    @Test func archiveRemovesFromDaysAndKeepsHistory() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = ExerciseRepositoryImpl(database: database)
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        let program = DatabaseFixtures.makeProgram()
        let day = DatabaseFixtures.makeDay(programId: program.id)
        let workout = DatabaseFixtures.makeWorkout(day: day, finishedAt: DatabaseFixtures.referenceDate)
        let workoutExercise = DatabaseFixtures.makeWorkoutExercise(workoutId: workout.id, exerciseId: exercise.id)
        try await database.writer.write { db in
            try ExerciseRecord(exercise).insert(db)
            try ProgramRecord(program).insert(db)
            try ProgramDayRecord(day).insert(db)
            try PlannedExerciseRecord(DatabaseFixtures.makePlannedExercise(dayId: day.id, exerciseId: exercise.id)).insert(db)
            try WorkoutRecord(workout).insert(db)
            try WorkoutExerciseRecord(workoutExercise).insert(db)
            try SetEntryRecord(DatabaseFixtures.makeSet(workoutExerciseId: workoutExercise.id)).insert(db)
        }

        try await repository.archive(id: exercise.id)

        let counts = try await database.reader.read { db in
            return (
                try PlannedExerciseRecord.fetchCount(db),
                try WorkoutExerciseRecord.fetchCount(db),
                try SetEntryRecord.fetchCount(db),
                try ExerciseRecord.filter(Column("id") == exercise.id.databaseText).fetchOne(db)?.isArchived
            )
        }
        #expect(counts.0 == 0)
        #expect(counts.1 == 1)
        #expect(counts.2 == 1)
        #expect(counts.3 == true)
    }
}
