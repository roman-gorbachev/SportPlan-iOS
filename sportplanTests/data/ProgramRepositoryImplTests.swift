import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

struct ProgramRepositoryImplTests {
    private static func makeDay(programId: UUID, name: String, label: String?) -> ProgramDay {
        return ProgramDay(id: UUID(), programId: programId, name: name, label: label, position: 0)
    }

    private static func makePlanned(dayId: UUID, exerciseId: UUID) -> PlannedExercise {
        return DatabaseFixtures.makePlannedExercise(dayId: dayId, exerciseId: exerciseId)
    }

    private static func insertExercises(_ exercises: [Exercise], equipment: [Equipment], into database: AppDatabase) async throws {
        try await database.writer.write { db in
            for item in equipment {
                try EquipmentRecord(item).insert(db)
            }
            for exercise in exercises {
                try ExerciseRecord(exercise).insert(db)
            }
        }
    }

    @Test func programsAreListedInOrderWithDayExerciseCounts() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = ProgramRepositoryImpl(database: database)
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        try await Self.insertExercises([exercise], equipment: [], into: database)

        let first = DatabaseFixtures.makeProgram()
        let firstDay = Self.makeDay(programId: first.id, name: "Грудь и трицепс", label: "A")
        let storedFirst = try await repository.createProgram(first, firstDay: firstDay)
        let second = Program(id: UUID(), name: "Разгрузка", position: 0, createdAt: DatabaseFixtures.referenceDate)
        let storedSecond = try await repository.createProgram(second, firstDay: Self.makeDay(programId: second.id, name: "Всё тело", label: nil))
        let laterDay = try await repository.addDay(Self.makeDay(programId: first.id, name: "Спина и бицепс", label: "B"))
        _ = try await repository.addPlannedExercise(Self.makePlanned(dayId: firstDay.id, exerciseId: exercise.id))

        #expect(storedFirst.position == 0)
        #expect(storedSecond.position == 1)
        #expect(laterDay.position == 1)

        var iterator = repository.observePrograms().makeAsyncIterator()
        let programs = try #require(try await iterator.next())
        #expect(programs.map(\.program.name) == ["Сила 3×", "Разгрузка"])
        #expect(programs[0].days.map(\.day.name) == ["Грудь и трицепс", "Спина и бицепс"])
        #expect(programs[0].days.map(\.exerciseCount) == [1, 0])
        #expect(programs[1].days.map(\.day.label) == [nil])
    }

    @Test func dayDetailFollowsOrderAndCarriesEquipment() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = ProgramRepositoryImpl(database: database)
        let bar = DatabaseFixtures.makeEquipment()
        let bench = DatabaseFixtures.makeExercise(load: .equipment(id: bar.id))
        let dips = DatabaseFixtures.makeExercise(load: .bodyweight)
        try await Self.insertExercises([bench, dips], equipment: [bar], into: database)
        let program = DatabaseFixtures.makeProgram()
        let day = Self.makeDay(programId: program.id, name: "Грудь и трицепс", label: "A")
        _ = try await repository.createProgram(program, firstDay: day)
        let benchPlanned = try await repository.addPlannedExercise(Self.makePlanned(dayId: day.id, exerciseId: bench.id))
        let dipsPlanned = try await repository.addPlannedExercise(Self.makePlanned(dayId: day.id, exerciseId: dips.id))
        #expect(dipsPlanned.position == 1)

        try await repository.reorderPlannedExercises(dayId: day.id, orderedIds: [dipsPlanned.id, benchPlanned.id])

        var iterator = repository.observeDay(id: day.id).makeAsyncIterator()
        let detail = try #require(try await iterator.next() ?? nil)
        #expect(detail.programName == program.name)
        #expect(detail.day.label == "A")
        #expect(detail.exercises.map(\.id) == [dipsPlanned.id, benchPlanned.id])
        #expect(detail.exercises.map(\.exercise.equipment) == [nil, bar])
        #expect(detail.exerciseIds == [bench.id, dips.id])
    }

    @Test func missingDayIsObservedAsNil() async throws {
        let repository = ProgramRepositoryImpl(database: try DatabaseFixtures.makeDatabase())
        var iterator = repository.observeDay(id: UUID()).makeAsyncIterator()
        let detail = try await iterator.next()
        #expect(detail == .some(nil))
    }

    @Test func exerciseIsAddedToDayOnlyOnce() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = ProgramRepositoryImpl(database: database)
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        try await Self.insertExercises([exercise], equipment: [], into: database)
        let program = DatabaseFixtures.makeProgram()
        let day = Self.makeDay(programId: program.id, name: "Грудь и трицепс", label: "A")
        _ = try await repository.createProgram(program, firstDay: day)
        _ = try await repository.addPlannedExercise(Self.makePlanned(dayId: day.id, exerciseId: exercise.id))

        await #expect(throws: ProgramError.exerciseAlreadyInDay) {
            _ = try await repository.addPlannedExercise(Self.makePlanned(dayId: day.id, exerciseId: exercise.id))
        }
        await #expect(throws: ProgramError.notFound) {
            _ = try await repository.addPlannedExercise(Self.makePlanned(dayId: UUID(), exerciseId: exercise.id))
        }
        let count = try await database.reader.read { db in
            return try PlannedExerciseRecord.fetchCount(db)
        }
        #expect(count == 1)
    }

    @Test func updatesProgramDayAndTargets() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = ProgramRepositoryImpl(database: database)
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        try await Self.insertExercises([exercise], equipment: [], into: database)
        let program = DatabaseFixtures.makeProgram()
        let day = Self.makeDay(programId: program.id, name: "Грудь и трицепс", label: "A")
        _ = try await repository.createProgram(program, firstDay: day)
        let planned = try await repository.addPlannedExercise(Self.makePlanned(dayId: day.id, exerciseId: exercise.id))
        let targets = PlannedExerciseTargets(sets: 5, reps: RepRange(min: 5, max: 5), restSeconds: 180)

        try await repository.renameProgram(id: program.id, name: "Сила 4×")
        try await repository.updateDay(id: day.id, name: "Жимовой день", label: nil)
        try await repository.updateTargets(plannedExerciseId: planned.id, targets: targets)

        var iterator = repository.observeDay(id: day.id).makeAsyncIterator()
        let detail = try #require(try await iterator.next() ?? nil)
        #expect(detail.programName == "Сила 4×")
        #expect(detail.day.name == "Жимовой день")
        #expect(detail.day.label == nil)
        #expect(try await repository.plannedExercise(id: planned.id)?.targets == targets)

        await #expect(throws: ProgramError.notFound) {
            try await repository.renameProgram(id: UUID(), name: "Нет")
        }
        await #expect(throws: ProgramError.notFound) {
            _ = try await repository.addDay(Self.makeDay(programId: UUID(), name: "День", label: nil))
        }
    }

    @Test func removingFromDayKeepsOtherExercises() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = ProgramRepositoryImpl(database: database)
        let bench = DatabaseFixtures.makeExercise(load: .bodyweight)
        let dips = DatabaseFixtures.makeExercise(load: .bodyweight)
        try await Self.insertExercises([bench, dips], equipment: [], into: database)
        let program = DatabaseFixtures.makeProgram()
        let day = Self.makeDay(programId: program.id, name: "Грудь и трицепс", label: "A")
        _ = try await repository.createProgram(program, firstDay: day)
        let benchPlanned = try await repository.addPlannedExercise(Self.makePlanned(dayId: day.id, exerciseId: bench.id))
        let dipsPlanned = try await repository.addPlannedExercise(Self.makePlanned(dayId: day.id, exerciseId: dips.id))

        try await repository.removePlannedExercise(id: benchPlanned.id)

        #expect(try await repository.plannedExercise(id: benchPlanned.id) == nil)
        #expect(try await repository.plannedExercise(id: dipsPlanned.id) != nil)
    }

    @Test func deletingProgramKeepsWorkoutHistory() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = ProgramRepositoryImpl(database: database)
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        try await Self.insertExercises([exercise], equipment: [], into: database)
        let program = DatabaseFixtures.makeProgram()
        let day = Self.makeDay(programId: program.id, name: "Грудь и трицепс", label: "A")
        _ = try await repository.createProgram(program, firstDay: day)
        _ = try await repository.addPlannedExercise(Self.makePlanned(dayId: day.id, exerciseId: exercise.id))
        let workout = DatabaseFixtures.makeWorkout(day: day, finishedAt: DatabaseFixtures.referenceDate)
        try await database.writer.write { db in
            try WorkoutRecord(workout).insert(db)
        }

        try await repository.deleteProgram(id: program.id)

        let (dayCount, plannedCount, storedWorkout) = try await database.reader.read { db in
            return (
                try ProgramDayRecord.fetchCount(db),
                try PlannedExerciseRecord.fetchCount(db),
                try WorkoutRecord.fetchOne(db, key: workout.id)?.toDomainModel()
            )
        }
        #expect(dayCount == 0)
        #expect(plannedCount == 0)
        #expect(storedWorkout?.programDay == ProgramDaySnapshot(programDayId: nil, name: day.name, label: day.label))
    }

    @Test func deletingDayRemovesItsExercises() async throws {
        let database = try DatabaseFixtures.makeDatabase()
        let repository = ProgramRepositoryImpl(database: database)
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        try await Self.insertExercises([exercise], equipment: [], into: database)
        let program = DatabaseFixtures.makeProgram()
        let day = Self.makeDay(programId: program.id, name: "Грудь и трицепс", label: "A")
        _ = try await repository.createProgram(program, firstDay: day)
        _ = try await repository.addPlannedExercise(Self.makePlanned(dayId: day.id, exerciseId: exercise.id))

        try await repository.deleteDay(id: day.id)

        var iterator = repository.observePrograms().makeAsyncIterator()
        let programs = try await iterator.next()
        #expect(programs?.first?.days.isEmpty == true)
        let plannedCount = try await database.reader.read { db in
            return try PlannedExerciseRecord.fetchCount(db)
        }
        #expect(plannedCount == 0)
    }
}
