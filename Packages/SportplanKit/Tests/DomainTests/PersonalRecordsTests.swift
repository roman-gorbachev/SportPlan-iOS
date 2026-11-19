import Domain
import Testing

struct PersonalRecordsTests {
    @Test func weightedRecordsAreMaxWeightAndOneRepMax() {
        let exercise = DomainFixtures.makeLibraryExercise()
        let heavy = RecordFixtures.set(kilograms: 70, reps: 3, at: RecordFixtures.day(1))
        let volume = RecordFixtures.set(kilograms: 65, reps: 8, at: RecordFixtures.day(8))
        let history = ExerciseHistory(exercise: exercise, sessions: [
            RecordFixtures.session(day: 1, [heavy]),
            RecordFixtures.session(day: 8, [volume]),
        ])

        let records = PersonalRecords.make(history: history)

        #expect(records.map(\.kind) == [.maxWeight, .estimatedOneRepMax])
        #expect(records[0].entry == heavy)
        #expect(records[0].date == RecordFixtures.day(1))
        #expect(records[1].entry == volume)
        #expect(records[1].value == 82_333)
    }

    @Test func maxWeightPrefersMoreRepsAtTheSameWeight() {
        let exercise = DomainFixtures.makeLibraryExercise()
        let fewer = RecordFixtures.set(kilograms: 65, reps: 6, at: RecordFixtures.day(1))
        let more = RecordFixtures.set(kilograms: 65, reps: 8, at: RecordFixtures.day(2))
        let history = ExerciseHistory(exercise: exercise, sessions: [
            RecordFixtures.session(day: 1, [fewer]),
            RecordFixtures.session(day: 2, [more]),
        ])

        #expect(PersonalRecords.make(history: history).first?.entry == more)
    }

    @Test func bodyweightWithoutAddedWeightHasOnlyMaxReps() {
        let exercise = DomainFixtures.makeLibraryExercise(name: "Подтягивания", kind: nil)
        let history = ExerciseHistory(exercise: exercise, sessions: [
            RecordFixtures.session(day: 1, [RecordFixtures.set(kilograms: 0, reps: 12, at: RecordFixtures.day(1))]),
        ])

        let records = PersonalRecords.make(history: history)

        #expect(records.map(\.kind) == [.maxReps])
        #expect(records.first?.value == 12)
    }

    @Test func bodyweightWithAddedWeightShowsTheHeaviestSet() {
        let exercise = DomainFixtures.makeLibraryExercise(name: "Подтягивания", kind: nil)
        let weighted = RecordFixtures.set(kilograms: 15, reps: 6, at: RecordFixtures.day(2))
        let history = ExerciseHistory(exercise: exercise, sessions: [
            RecordFixtures.session(day: 1, [RecordFixtures.set(kilograms: 0, reps: 14, at: RecordFixtures.day(1))]),
            RecordFixtures.session(day: 2, [weighted]),
        ])

        let records = PersonalRecords.make(history: history)

        #expect(records.map(\.kind) == [.maxReps, .maxWeightedReps])
        #expect(records[0].value == 14)
        #expect(records[1].entry == weighted)
    }

    @Test func timedExerciseHasMaxDuration() {
        let exercise = DomainFixtures.makeLibraryExercise(name: "Планка", kind: nil, metric: .duration)
        let history = ExerciseHistory(exercise: exercise, sessions: [
            RecordFixtures.session(day: 1, [
                RecordFixtures.set(kilograms: 0, durationSeconds: 130, at: RecordFixtures.day(1)),
                RecordFixtures.set(kilograms: 0, durationSeconds: 100, isWarmup: true, at: RecordFixtures.day(1)),
            ]),
        ])

        let records = PersonalRecords.make(history: history)

        #expect(records.map(\.kind) == [.maxDuration])
        #expect(records.first?.value == 130)
    }
}
