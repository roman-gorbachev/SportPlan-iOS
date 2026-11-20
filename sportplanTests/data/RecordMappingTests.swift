import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

struct RecordMappingTests {
    @Test func equipmentRoundTrips() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let equipment = DatabaseFixtures.makeEquipment()
        let fetched = try database.writer.write { db in
            try EquipmentRecord(equipment).insert(db)
            return try EquipmentRecord.fetchOne(db, key: equipment.id)?.toDomainModel()
        }
        #expect(fetched == equipment)
    }

    @Test func exerciseWithEquipmentRoundTrips() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let equipment = DatabaseFixtures.makeEquipment()
        let exercise = DatabaseFixtures.makeExercise(load: .equipment(id: equipment.id))
        let fetched = try database.writer.write { db in
            try EquipmentRecord(equipment).insert(db)
            try ExerciseRecord(exercise).insert(db)
            return try ExerciseRecord.fetchOne(db, key: exercise.id)?.toDomainModel()
        }
        #expect(fetched == exercise)
    }

    @Test func bodyweightExerciseRoundTrips() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        let fetched = try database.writer.write { db in
            try ExerciseRecord(exercise).insert(db)
            return try ExerciseRecord.fetchOne(db, key: exercise.id)?.toDomainModel()
        }
        #expect(fetched == exercise)
    }

    @Test func programTreeRoundTrips() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        let program = DatabaseFixtures.makeProgram()
        let day = DatabaseFixtures.makeDay(programId: program.id)
        var planned = DatabaseFixtures.makePlannedExercise(dayId: day.id, exerciseId: exercise.id)
        planned.startWeight = Weight(kilograms: 42.5)
        let fetched = try database.writer.write { db in
            try ExerciseRecord(exercise).insert(db)
            try ProgramRecord(program).insert(db)
            try ProgramDayRecord(day).insert(db)
            try PlannedExerciseRecord(planned).insert(db)
            return (
                program: try ProgramRecord.fetchOne(db, key: program.id)?.toDomainModel(),
                day: try ProgramDayRecord.fetchOne(db, key: day.id)?.toDomainModel(),
                planned: try PlannedExerciseRecord.fetchOne(db, key: planned.id)?.toDomainModel()
            )
        }
        #expect(fetched.program == program)
        #expect(fetched.day == day)
        #expect(fetched.planned == planned)
    }

    @Test func workoutTreeRoundTrips() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        let program = DatabaseFixtures.makeProgram()
        let day = DatabaseFixtures.makeDay(programId: program.id)
        let workout = DatabaseFixtures.makeWorkout(day: day, finishedAt: nil)
        let workoutExercise = WorkoutExercise(
            id: UUID(),
            workoutId: workout.id,
            exerciseId: exercise.id,
            position: 0,
            targetSets: 2,
            targetReps: nil,
            restSeconds: Exercise.defaultRestSeconds,
            targetDurationSeconds: 45
        )
        let entry = DatabaseFixtures.makeSet(workoutExerciseId: workoutExercise.id)
        let fetched = try database.writer.write { db in
            try ExerciseRecord(exercise).insert(db)
            try ProgramRecord(program).insert(db)
            try ProgramDayRecord(day).insert(db)
            try WorkoutRecord(workout).insert(db)
            try WorkoutExerciseRecord(workoutExercise).insert(db)
            try SetEntryRecord(entry).insert(db)
            return (
                workout: try WorkoutRecord.fetchOne(db, key: workout.id)?.toDomainModel(),
                workoutExercise: try WorkoutExerciseRecord.fetchOne(db, key: workoutExercise.id)?.toDomainModel(),
                entry: try SetEntryRecord.fetchOne(db, key: entry.id)?.toDomainModel()
            )
        }
        #expect(fetched.workout == workout)
        #expect(fetched.workoutExercise == workoutExercise)
        #expect(fetched.entry == entry)
    }

    @Test func plateRoundTrips() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let plate = Plate(id: UUID(), weight: Weight(kilograms: 0.5), color: PlateColor(rgb: 0x0A0B0C))
        let fetched = try database.writer.write { db in
            try PlateRecord(plate).insert(db)
            return try PlateRecord.fetchOne(db, key: plate.id)?.toDomainModel()
        }
        #expect(fetched == plate)
    }

    @Test func plateColorParsesHex() {
        #expect(PlateColor(hexString: "#0A0B0C") == PlateColor(rgb: 0x0A0B0C))
        #expect(PlateColor(rgb: 0x0000FF).hexString == "#0000FF")
        #expect(PlateColor(hexString: "0A0B0C") == nil)
        #expect(PlateColor(hexString: "#GGGGGG") == nil)
    }
}
