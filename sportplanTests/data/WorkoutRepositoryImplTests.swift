import Domain
import Foundation
import GRDB
import Testing
@testable import sportplan

struct WorkoutRepositoryImplTests {
    private struct Context {
        let database: AppDatabase
        let repository: WorkoutRepositoryImpl
        let programs: ProgramRepositoryImpl
        let bar: Equipment
        let bench: Exercise
        let dips: Exercise
        let day: ProgramDay
    }

    private static func makeContext() async throws -> Context {
        let database = try DatabaseFixtures.makeDatabase()
        let bar = DatabaseFixtures.makeEquipment()
        let bench = DatabaseFixtures.makeExercise(load: .equipment(id: bar.id))
        var bodyweight = DatabaseFixtures.makeExercise(load: .bodyweight)
        bodyweight.name = "Брусья"
        let dips = bodyweight
        try await database.writer.write { db in
            try EquipmentRecord(bar).insert(db)
            try ExerciseRecord(bench).insert(db)
            try ExerciseRecord(dips).insert(db)
        }
        let programs = ProgramRepositoryImpl(database: database)
        let program = DatabaseFixtures.makeProgram()
        let day = DatabaseFixtures.makeDay(programId: program.id)
        _ = try await programs.createProgram(program, firstDay: day)
        return Context(
            database: database,
            repository: WorkoutRepositoryImpl(database: database),
            programs: programs,
            bar: bar,
            bench: bench,
            dips: dips,
            day: day
        )
    }

    private static func makeWorkout(day: ProgramDay?, startedAt: Date = DatabaseFixtures.referenceDate) -> Workout {
        return Workout(
            id: UUID(),
            programDay: day.map { day in
                return ProgramDaySnapshot(programDayId: day.id, name: day.name, label: day.label)
            },
            startedAt: startedAt,
            finishedAt: nil,
            note: nil,
            rest: nil
        )
    }

    private static func makeExercise(workoutId: UUID, exerciseId: UUID, position: Int) -> WorkoutExercise {
        var item = DatabaseFixtures.makeWorkoutExercise(workoutId: workoutId, exerciseId: exerciseId)
        item.position = position
        return item
    }

    private static func makeSet(
        workoutExerciseId: UUID,
        position: Int,
        kilograms: Double,
        reps: Int,
        isWarmup: Bool = false,
        completed: Bool
    ) -> SetEntry {
        return SetEntry(
            id: UUID(),
            workoutExerciseId: workoutExerciseId,
            position: position,
            weight: Weight(kilograms: kilograms),
            reps: reps,
            durationSeconds: nil,
            isWarmup: isWarmup,
            startedAt: nil,
            completedAt: completed ? DatabaseFixtures.referenceDate : nil
        )
    }

    private static func finishedWorkout(
        context: Context,
        startedAt: Date,
        hasTargets: Bool = true,
        sets: [(kilograms: Double, reps: Int, isWarmup: Bool, completed: Bool)]
    ) async throws {
        let workout = makeWorkout(day: hasTargets ? context.day : nil, startedAt: startedAt)
        let planned = makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)
        let item = hasTargets ? planned : WorkoutExercise(
            id: planned.id,
            workoutId: planned.workoutId,
            exerciseId: planned.exerciseId,
            position: planned.position,
            targetSets: nil,
            targetReps: nil,
            restSeconds: planned.restSeconds
        )
        let entries = sets.enumerated().map { position, values in
            return makeSet(
                workoutExerciseId: item.id,
                position: position,
                kilograms: values.kilograms,
                reps: values.reps,
                isWarmup: values.isWarmup,
                completed: values.completed
            )
        }
        try await context.repository.start(workout, exercises: [item], sets: entries)
        try await context.database.writer.write { db in
            _ = try WorkoutRecord
                .filter(Column("id") == workout.id.databaseText)
                .updateAll(db, Column("finished_at").set(to: startedAt.addingTimeInterval(3_600)))
        }
    }

    @Test func startStoresSnapshotAndRowsAndRejectsSecondActive() async throws {
        let context = try await Self.makeContext()
        let workout = Self.makeWorkout(day: context.day)
        let bench = Self.makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)
        let dips = Self.makeExercise(workoutId: workout.id, exerciseId: context.dips.id, position: 1)
        let sets = [
            Self.makeSet(workoutExerciseId: bench.id, position: 0, kilograms: 60, reps: 8, completed: false),
            Self.makeSet(workoutExerciseId: bench.id, position: 1, kilograms: 62.5, reps: 8, completed: false),
            Self.makeSet(workoutExerciseId: dips.id, position: 0, kilograms: 0, reps: 10, completed: false),
        ]
        try await context.repository.start(workout, exercises: [dips, bench], sets: sets.reversed())

        let active = try #require(try await context.repository.activeWorkout())
        #expect(active.workout.programDay?.name == context.day.name)
        #expect(active.programName == DatabaseFixtures.makeProgram().name)
        #expect(active.exercises.map(\.exercise.id) == [context.bench.id, context.dips.id])
        #expect(active.exercises[0].exercise.equipment == context.bar)
        #expect(active.exercises[0].sets.map(\.weight) == [Weight(kilograms: 60), Weight(kilograms: 62.5)])
        #expect(active.exercises[1].sets.count == 1)

        await #expect(throws: WorkoutError.alreadyActive) {
            try await context.repository.start(Self.makeWorkout(day: nil), exercises: [], sets: [])
        }
    }

    @Test func observationFollowsChanges() async throws {
        let context = try await Self.makeContext()
        var iterator = context.repository.observeActive().makeAsyncIterator()
        #expect(try await iterator.next() == .some(nil))

        let workout = Self.makeWorkout(day: nil)
        try await context.repository.start(workout, exercises: [], sets: [])
        let started = try #require(try await iterator.next() ?? nil)
        #expect(started.id == workout.id)
        #expect(started.programName == nil)

        try await context.repository.updateNote(workoutId: workout.id, note: "Плечо не беспокоило")
        let noted = try #require(try await iterator.next() ?? nil)
        #expect(noted.workout.note == "Плечо не беспокоило")
    }

    @Test func previousSetsComeFromTheLatestFinishedWorkoutWithCompletedSets() async throws {
        let context = try await Self.makeContext()
        let day = TimeInterval(86_400)
        try await Self.finishedWorkout(
            context: context,
            startedAt: DatabaseFixtures.referenceDate,
            sets: [(kilograms: 55, reps: 10, isWarmup: false, completed: true)]
        )
        try await Self.finishedWorkout(
            context: context,
            startedAt: DatabaseFixtures.referenceDate.addingTimeInterval(day),
            sets: [
                (kilograms: 40, reps: 10, isWarmup: true, completed: true),
                (kilograms: 60, reps: 8, isWarmup: false, completed: true),
                (kilograms: 62.5, reps: 7, isWarmup: false, completed: true),
                (kilograms: 65, reps: 5, isWarmup: false, completed: false),
            ]
        )

        let previous = try await context.repository.previousSets(exerciseId: context.bench.id)
        #expect(previous.map(\.weight) == [Weight(kilograms: 40), Weight(kilograms: 60), Weight(kilograms: 62.5)])
        #expect(previous.map(\.isWarmup) == [true, false, false])
        #expect(try await context.repository.previousSets(exerciseId: context.dips.id).isEmpty)

        let workout = Self.makeWorkout(day: context.day, startedAt: DatabaseFixtures.referenceDate.addingTimeInterval(day * 2))
        let item = Self.makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)
        try await context.repository.start(workout, exercises: [item], sets: [])
        let active = try #require(try await context.repository.activeWorkout())
        #expect(active.exercises.first?.previousSets.map(\.reps) == [10, 8, 7])
    }

    @Test func activeExerciseCarriesTargetsOfThePreviousWorkout() async throws {
        let context = try await Self.makeContext()
        let day = TimeInterval(86_400)
        try await Self.finishedWorkout(
            context: context,
            startedAt: DatabaseFixtures.referenceDate,
            sets: [(kilograms: 60, reps: 12, isWarmup: false, completed: true)]
        )
        let workout = Self.makeWorkout(day: context.day, startedAt: DatabaseFixtures.referenceDate.addingTimeInterval(day))
        let item = Self.makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)
        let dips = Self.makeExercise(workoutId: workout.id, exerciseId: context.dips.id, position: 1)
        try await context.repository.start(workout, exercises: [item, dips], sets: [])

        let active = try #require(try await context.repository.activeWorkout())
        let previous = try #require(active.exercises.first?.previousWorkoutExercise)
        #expect(previous.targetSets == 3)
        #expect(previous.targetReps == RepRange(min: 8, max: 12))
        #expect(previous.workoutId != workout.id)
        #expect(active.exercises.last?.previousWorkoutExercise == nil)
    }

    @Test func previousWorkoutOutsideThePlanHasNoTargets() async throws {
        let context = try await Self.makeContext()
        let day = TimeInterval(86_400)
        try await Self.finishedWorkout(
            context: context,
            startedAt: DatabaseFixtures.referenceDate,
            hasTargets: false,
            sets: [(kilograms: 60, reps: 12, isWarmup: false, completed: true)]
        )
        let workout = Self.makeWorkout(day: context.day, startedAt: DatabaseFixtures.referenceDate.addingTimeInterval(day))
        try await context.repository.start(
            workout,
            exercises: [Self.makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)],
            sets: []
        )

        let active = try #require(try await context.repository.activeWorkout())
        let previous = try #require(active.exercises.first?.previousWorkoutExercise)
        #expect(previous.targetSets == nil)
        #expect(previous.targetReps == nil)
        #expect(active.exercises.first?.previousSets.map(\.reps) == [12])
    }

    @Test func updateSetsWritesEveryEntryInOneObservedChange() async throws {
        let context = try await Self.makeContext()
        let workout = Self.makeWorkout(day: context.day)
        let item = Self.makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)
        let sets = (0..<3).map { position in
            return Self.makeSet(workoutExerciseId: item.id, position: position, kilograms: 60, reps: 12, completed: false)
        }
        try await context.repository.start(workout, exercises: [item], sets: sets)
        var iterator = context.repository.observeActive().makeAsyncIterator()
        _ = try await iterator.next()

        let heavier = sets.map { entry in
            var changed = entry
            changed.weight = Weight(kilograms: 62.5)
            return changed
        }
        try await context.repository.updateSets(heavier)

        let updated = try #require(try await iterator.next() ?? nil)
        #expect(updated.exercises.first?.sets.map(\.weight) == Array(repeating: Weight(kilograms: 62.5), count: 3))
        #expect(updated.exercises.first?.sets.map(\.reps) == [12, 12, 12])
    }

    @Test func addExerciseAppendsAndRejectsDuplicates() async throws {
        let context = try await Self.makeContext()
        let workout = Self.makeWorkout(day: nil)
        try await context.repository.start(workout, exercises: [Self.makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)], sets: [])
        let dips = Self.makeExercise(workoutId: workout.id, exerciseId: context.dips.id, position: 0)
        try await context.repository.addExercise(dips, sets: [Self.makeSet(workoutExerciseId: dips.id, position: 0, kilograms: 0, reps: 10, completed: false)])

        let active = try #require(try await context.repository.activeWorkout())
        #expect(active.exercises.map(\.exercise.id) == [context.bench.id, context.dips.id])
        #expect(active.exercises.map(\.workoutExercise.position) == [0, 1])
        await #expect(throws: WorkoutError.exerciseAlreadyInWorkout) {
            try await context.repository.addExercise(Self.makeExercise(workoutId: workout.id, exerciseId: context.dips.id, position: 0), sets: [])
        }
    }

    @Test func addSetShiftsLaterRowsAndUpdateAndRemoveWork() async throws {
        let context = try await Self.makeContext()
        let workout = Self.makeWorkout(day: nil)
        let item = Self.makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)
        let working = Self.makeSet(workoutExerciseId: item.id, position: 0, kilograms: 60, reps: 8, completed: false)
        try await context.repository.start(workout, exercises: [item], sets: [working])

        let warmup = Self.makeSet(workoutExerciseId: item.id, position: 0, kilograms: 40, reps: 10, isWarmup: true, completed: false)
        try await context.repository.addSet(warmup)
        var completed = working
        completed.reps = 9
        completed.completedAt = DatabaseFixtures.referenceDate
        try await context.repository.updateSet(completed)

        var sets = try #require(try await context.repository.activeWorkout()?.exercises.first).sets
        #expect(sets.map(\.id) == [warmup.id, working.id])
        #expect(sets.map(\.position) == [0, 1])
        #expect(sets[1].reps == 9)
        #expect(sets[1].state == .completed)

        try await context.repository.removeSet(id: warmup.id)
        sets = try #require(try await context.repository.activeWorkout()?.exercises.first).sets
        #expect(sets.map(\.id) == [working.id])
        await #expect(throws: WorkoutError.notFound) {
            try await context.repository.updateSet(warmup)
        }
    }

    @Test func finishDropsUnfinishedRowsAndEmptyExercises() async throws {
        let context = try await Self.makeContext()
        let workout = Self.makeWorkout(day: context.day)
        let bench = Self.makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)
        let dips = Self.makeExercise(workoutId: workout.id, exerciseId: context.dips.id, position: 1)
        let done = Self.makeSet(workoutExerciseId: bench.id, position: 0, kilograms: 60, reps: 8, completed: true)
        try await context.repository.start(workout, exercises: [bench, dips], sets: [
            done,
            Self.makeSet(workoutExerciseId: bench.id, position: 1, kilograms: 60, reps: 8, completed: false),
            Self.makeSet(workoutExerciseId: dips.id, position: 0, kilograms: 0, reps: 10, completed: false),
        ])
        let finishedAt = DatabaseFixtures.referenceDate.addingTimeInterval(3_600)
        try await context.repository.finish(workoutId: workout.id, at: finishedAt)

        #expect(try await context.repository.activeWorkout() == nil)
        let (storedFinishedAt, exerciseIds, setIds) = try await context.database.reader.read { db in
            let stored = try WorkoutRecord.fetchOne(db)
            let exerciseIds = try WorkoutExerciseRecord.fetchAll(db).map(\.id)
            let setIds = try SetEntryRecord.fetchAll(db).map(\.id)
            return (stored?.finishedAt, exerciseIds, setIds)
        }
        #expect(storedFinishedAt == finishedAt)
        #expect(exerciseIds == [bench.id])
        #expect(setIds == [done.id])

        var iterator = context.programs.observePrograms().makeAsyncIterator()
        let programs = try #require(try await iterator.next())
        #expect(programs.first?.days.first?.lastWorkoutAt == DatabaseFixtures.referenceDate)
        #expect(programs.first?.days.first?.exerciseNames == [])
    }

    @Test func restIsStoredAndClearedOnFinish() async throws {
        let context = try await Self.makeContext()
        let workout = Self.makeWorkout(day: nil)
        let item = Self.makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)
        try await context.repository.start(workout, exercises: [item], sets: [
            Self.makeSet(workoutExerciseId: item.id, position: 0, kilograms: 60, reps: 8, completed: true),
        ])
        let rest = RestPeriod(startedAt: DatabaseFixtures.referenceDate, seconds: 120)
        try await context.repository.updateRest(workoutId: workout.id, rest: rest)
        #expect(try await context.repository.activeWorkout()?.workout.rest == rest)

        try await context.repository.updateRest(workoutId: workout.id, rest: nil)
        #expect(try await context.repository.activeWorkout()?.workout.rest == nil)

        try await context.repository.updateRest(workoutId: workout.id, rest: rest)
        try await context.repository.finish(workoutId: workout.id, at: DatabaseFixtures.referenceDate.addingTimeInterval(600))
        let stored = try await context.database.reader.read { db in
            return try WorkoutRecord.fetchOne(db)
        }
        #expect(stored?.restStartedAt == nil)
        #expect(stored?.restEndsAt == nil)
        await #expect(throws: WorkoutError.noActiveWorkout) {
            try await context.repository.updateRest(workoutId: workout.id, rest: rest)
        }
    }

    @Test func cancelRemovesTheWorkoutWithRows() async throws {
        let context = try await Self.makeContext()
        let workout = Self.makeWorkout(day: nil)
        let item = Self.makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)
        try await context.repository.start(workout, exercises: [item], sets: [
            Self.makeSet(workoutExerciseId: item.id, position: 0, kilograms: 60, reps: 8, completed: true),
        ])
        try await context.repository.cancel(workoutId: workout.id)

        let counts = try await context.database.reader.read { db in
            return [
                try WorkoutRecord.fetchCount(db),
                try WorkoutExerciseRecord.fetchCount(db),
                try SetEntryRecord.fetchCount(db),
            ]
        }
        #expect(counts == [0, 0, 0])
    }

    @Test func deletingTheProgramDayKeepsTheSnapshot() async throws {
        let context = try await Self.makeContext()
        let workout = Self.makeWorkout(day: context.day)
        try await context.repository.start(workout, exercises: [], sets: [])
        try await context.programs.deleteDay(id: context.day.id)

        let active = try #require(try await context.repository.activeWorkout())
        #expect(active.workout.programDay?.programDayId == nil)
        #expect(active.workout.programDay?.name == context.day.name)
        #expect(active.workout.programDay?.label == context.day.label)
        #expect(active.programName == nil)
    }

    @Test func exerciseHistoryHasCompletedWorkingSetsNewestFirst() async throws {
        let context = try await Self.makeContext()
        let day = TimeInterval(86_400)
        try await Self.finishedWorkout(
            context: context,
            startedAt: DatabaseFixtures.referenceDate,
            sets: [
                (kilograms: 40, reps: 10, isWarmup: true, completed: true),
                (kilograms: 60, reps: 8, isWarmup: false, completed: true),
            ]
        )
        try await Self.finishedWorkout(
            context: context,
            startedAt: DatabaseFixtures.referenceDate.addingTimeInterval(day),
            sets: [(kilograms: 62.5, reps: 8, isWarmup: false, completed: true)]
        )
        let workout = Self.makeWorkout(day: nil, startedAt: DatabaseFixtures.referenceDate.addingTimeInterval(day * 2))
        let bench = Self.makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)
        let dips = Self.makeExercise(workoutId: workout.id, exerciseId: context.dips.id, position: 1)
        try await context.repository.start(workout, exercises: [bench, dips], sets: [
            Self.makeSet(workoutExerciseId: bench.id, position: 0, kilograms: 65, reps: 5, completed: true),
            Self.makeSet(workoutExerciseId: bench.id, position: 1, kilograms: 65, reps: 5, completed: false),
            Self.makeSet(workoutExerciseId: dips.id, position: 0, kilograms: 0, reps: 12, completed: true),
        ])

        var iterator = context.repository.observeExerciseHistory(exerciseId: context.bench.id).makeAsyncIterator()
        let history = try #require(try await iterator.next() ?? nil)

        #expect(history.exercise.id == context.bench.id)
        #expect(history.sessions.map(\.workoutId).first == workout.id)
        #expect(history.sessions.map { session in return session.sets.map(\.weight) } == [
            [Weight(kilograms: 65)],
            [Weight(kilograms: 62.5)],
            [Weight(kilograms: 60)],
        ])

        try await context.repository.addSet(
            Self.makeSet(workoutExerciseId: bench.id, position: 2, kilograms: 67.5, reps: 5, completed: true)
        )
        let updated = try #require(try await iterator.next() ?? nil)
        #expect(updated.sessions.first?.sets.map(\.weight) == [Weight(kilograms: 65), Weight(kilograms: 67.5)])
    }

    @Test func exerciseHistoryOfAMissingExerciseIsNil() async throws {
        let context = try await Self.makeContext()
        var iterator = context.repository.observeExerciseHistory(exerciseId: UUID()).makeAsyncIterator()

        #expect(try await iterator.next() == .some(nil))
    }

    @Test func activeRecordBaselineComesFromFinishedWorkoutsOnly() async throws {
        let context = try await Self.makeContext()
        try await Self.finishedWorkout(
            context: context,
            startedAt: DatabaseFixtures.referenceDate,
            sets: [(kilograms: 60, reps: 8, isWarmup: false, completed: true)]
        )
        let workout = Self.makeWorkout(day: nil, startedAt: DatabaseFixtures.referenceDate.addingTimeInterval(86_400))
        let item = Self.makeExercise(workoutId: workout.id, exerciseId: context.bench.id, position: 0)
        let equal = Self.makeSet(workoutExerciseId: item.id, position: 0, kilograms: 60, reps: 8, completed: true)
        try await context.repository.start(workout, exercises: [item], sets: [equal])

        let active = try #require(try await context.repository.activeWorkout())

        #expect(active.exercises.first?.recordSetIds.isEmpty == true)
        #expect(active.exercises.first?.recordBaseline == RecordBaseline(sets: [
            Self.makeSet(workoutExerciseId: item.id, position: 0, kilograms: 60, reps: 8, completed: true),
        ]))
    }
}
