import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

struct SchemaConstraintTests {
    @Test func rejectsPlateOutsideBounds() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let tooLight = Plate(id: UUID(), weight: Weight(grams: 249), color: PlateColor(rgb: 0))
        let tooHeavy = Plate(id: UUID(), weight: Weight(grams: 50_001), color: PlateColor(rgb: 0))
        try database.writer.write { db in
            #expect(throws: DatabaseError.self) { try PlateRecord(tooLight).insert(db) }
            #expect(throws: DatabaseError.self) { try PlateRecord(tooHeavy).insert(db) }
        }
    }

    @Test func rejectsDuplicatePlateWeight() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let duplicate = Plate(id: UUID(), weight: Weight(kilograms: 20), color: PlateColor(rgb: 0))
        try database.writer.write { db in
            #expect(throws: DatabaseError.self) { try PlateRecord(duplicate).insert(db) }
        }
    }

    @Test func rejectsSecondActiveWorkout() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let first = DatabaseFixtures.makeWorkout(day: nil, finishedAt: nil)
        let second = DatabaseFixtures.makeWorkout(day: nil, finishedAt: nil)
        try database.writer.write { db in
            try WorkoutRecord(first).insert(db)
            #expect(throws: DatabaseError.self) { try WorkoutRecord(second).insert(db) }
        }
    }

    @Test func allowsManyFinishedWorkouts() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let finishedAt = DatabaseFixtures.referenceDate
        let workouts = [
            DatabaseFixtures.makeWorkout(day: nil, finishedAt: finishedAt),
            DatabaseFixtures.makeWorkout(day: nil, finishedAt: finishedAt),
            DatabaseFixtures.makeWorkout(day: nil, finishedAt: nil),
        ]
        let count = try database.writer.write { db in
            for workout in workouts {
                try WorkoutRecord(workout).insert(db)
            }
            return try WorkoutRecord.fetchCount(db)
        }
        #expect(count == workouts.count)
    }

    @Test func rejectsUnknownEquipmentKind() throws {
        let database = try DatabaseFixtures.makeDatabase()
        var record = EquipmentRecord(DatabaseFixtures.makeEquipment())
        record.kind = "kettlebell"
        try database.writer.write { db in
            #expect(throws: DatabaseError.self) { try record.insert(db) }
        }
    }

    @Test func rejectsHalfSetRepRange() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        let workout = DatabaseFixtures.makeWorkout(day: nil, finishedAt: nil)
        var record = WorkoutExerciseRecord(DatabaseFixtures.makeWorkoutExercise(workoutId: workout.id, exerciseId: exercise.id))
        record.targetRepsMax = nil
        try database.writer.write { db in
            try ExerciseRecord(exercise).insert(db)
            try WorkoutRecord(workout).insert(db)
            #expect(throws: DatabaseError.self) { try record.insert(db) }
        }
    }

    @Test func rejectsHalfSetRestPeriod() throws {
        let database = try DatabaseFixtures.makeDatabase()
        var record = WorkoutRecord(DatabaseFixtures.makeWorkout(day: nil, finishedAt: nil))
        record.restEndsAt = nil
        try database.writer.write { db in
            #expect(throws: DatabaseError.self) { try record.insert(db) }
        }
    }

    @Test func deletingProgramCascadesToDaysAndPlannedExercises() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        let program = DatabaseFixtures.makeProgram()
        let day = DatabaseFixtures.makeDay(programId: program.id)
        let planned = DatabaseFixtures.makePlannedExercise(dayId: day.id, exerciseId: exercise.id)
        let counts = try database.writer.write { db in
            try ExerciseRecord(exercise).insert(db)
            try ProgramRecord(program).insert(db)
            try ProgramDayRecord(day).insert(db)
            try PlannedExerciseRecord(planned).insert(db)
            _ = try ProgramRecord.deleteOne(db, key: program.id)
            return (days: try ProgramDayRecord.fetchCount(db), planned: try PlannedExerciseRecord.fetchCount(db))
        }
        #expect(counts.days == 0)
        #expect(counts.planned == 0)
    }

    @Test func deletingWorkoutCascadesToExercisesAndSets() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        let workout = DatabaseFixtures.makeWorkout(day: nil, finishedAt: nil)
        let workoutExercise = DatabaseFixtures.makeWorkoutExercise(workoutId: workout.id, exerciseId: exercise.id)
        let entry = DatabaseFixtures.makeSet(workoutExerciseId: workoutExercise.id)
        let counts = try database.writer.write { db in
            try ExerciseRecord(exercise).insert(db)
            try WorkoutRecord(workout).insert(db)
            try WorkoutExerciseRecord(workoutExercise).insert(db)
            try SetEntryRecord(entry).insert(db)
            _ = try WorkoutRecord.deleteOne(db, key: workout.id)
            return (exercises: try WorkoutExerciseRecord.fetchCount(db), sets: try SetEntryRecord.fetchCount(db))
        }
        #expect(counts.exercises == 0)
        #expect(counts.sets == 0)
    }

    @Test func refusesToDeleteExerciseWithHistory() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let exercise = DatabaseFixtures.makeExercise(load: .bodyweight)
        let workout = DatabaseFixtures.makeWorkout(day: nil, finishedAt: nil)
        let workoutExercise = DatabaseFixtures.makeWorkoutExercise(workoutId: workout.id, exerciseId: exercise.id)
        try database.writer.write { db in
            try ExerciseRecord(exercise).insert(db)
            try WorkoutRecord(workout).insert(db)
            try WorkoutExerciseRecord(workoutExercise).insert(db)
            #expect(throws: DatabaseError.self) { try ExerciseRecord.deleteOne(db, key: exercise.id) }
        }
    }

    @Test func refusesToDeleteEquipmentInUse() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let equipment = DatabaseFixtures.makeEquipment()
        let exercise = DatabaseFixtures.makeExercise(load: .equipment(id: equipment.id))
        try database.writer.write { db in
            try EquipmentRecord(equipment).insert(db)
            try ExerciseRecord(exercise).insert(db)
            #expect(throws: DatabaseError.self) { try EquipmentRecord.deleteOne(db, key: equipment.id) }
        }
    }

    @Test func deletingDayKeepsWorkoutSnapshot() throws {
        let database = try DatabaseFixtures.makeDatabase()
        let program = DatabaseFixtures.makeProgram()
        let day = DatabaseFixtures.makeDay(programId: program.id)
        let workout = DatabaseFixtures.makeWorkout(day: day, finishedAt: DatabaseFixtures.referenceDate)
        let fetched = try database.writer.write { db in
            try ProgramRecord(program).insert(db)
            try ProgramDayRecord(day).insert(db)
            try WorkoutRecord(workout).insert(db)
            _ = try ProgramDayRecord.deleteOne(db, key: day.id)
            return try WorkoutRecord.fetchOne(db, key: workout.id)?.toDomainModel()
        }
        #expect(fetched?.programDay == ProgramDaySnapshot(programDayId: nil, name: day.name, label: day.label))
    }
}
