import Domain
import Foundation
import Testing

struct RecordBaselineTests {
    private let earlier = RecordFixtures.day(0)
    private let later = RecordFixtures.day(1)

    @Test func emptyHistoryGivesNoRecord() {
        let entry = RecordFixtures.set(kilograms: 100, reps: 5, at: later)

        #expect(!RecordBaseline.empty.isRecord(entry, profile: .weighted))
    }

    @Test func equalWeightIsNotARecord() {
        let baseline = RecordBaseline(sets: [RecordFixtures.set(kilograms: 60, reps: 8, at: earlier)])

        #expect(!baseline.isRecord(RecordFixtures.set(kilograms: 60, reps: 8, at: later), profile: .weighted))
        #expect(baseline.isRecord(RecordFixtures.set(kilograms: 62.5, reps: 8, at: later), profile: .weighted))
    }

    @Test func moreRepsAtTheSameWeightBeatTheOneRepMax() {
        let baseline = RecordBaseline(sets: [RecordFixtures.set(kilograms: 60, reps: 8, at: earlier)])

        #expect(baseline.isRecord(RecordFixtures.set(kilograms: 60, reps: 9, at: later), profile: .weighted))
        #expect(!baseline.isRecord(RecordFixtures.set(kilograms: 55, reps: 9, at: later), profile: .weighted))
    }

    @Test func warmupsAndPlannedSetsAreIgnored() {
        let baseline = RecordBaseline(sets: [
            RecordFixtures.set(kilograms: 100, reps: 5, isWarmup: true, at: earlier),
            DomainFixtures.makeSet(position: 1, kilograms: 100, reps: 5, completedAt: nil),
            RecordFixtures.set(kilograms: 60, reps: 5, at: earlier),
        ])

        #expect(baseline.isRecord(RecordFixtures.set(kilograms: 70, reps: 5, at: later), profile: .weighted))
    }

    @Test func bodyweightSetIsARecordWhenNoEarlierSetCoversIt() {
        let baseline = RecordBaseline(sets: [
            RecordFixtures.set(kilograms: 15, reps: 6, at: earlier),
            RecordFixtures.set(kilograms: 0, reps: 14, at: earlier),
        ])

        #expect(baseline.isRecord(RecordFixtures.set(kilograms: 5, reps: 10, at: later), profile: .bodyweightReps))
        #expect(!baseline.isRecord(RecordFixtures.set(kilograms: 10, reps: 6, at: later), profile: .bodyweightReps))
        #expect(!baseline.isRecord(RecordFixtures.set(kilograms: 0, reps: 14, at: later), profile: .bodyweightReps))
        #expect(baseline.isRecord(RecordFixtures.set(kilograms: 0, reps: 15, at: later), profile: .bodyweightReps))
    }

    @Test func longerDurationIsARecord() {
        let baseline = RecordBaseline(sets: [RecordFixtures.set(kilograms: 0, durationSeconds: 90, at: earlier)])

        #expect(!baseline.isRecord(RecordFixtures.set(kilograms: 0, durationSeconds: 90, at: later), profile: .duration))
        #expect(baseline.isRecord(RecordFixtures.set(kilograms: 0, durationSeconds: 91, at: later), profile: .duration))
    }

    @Test func recordSetsFollowCompletionOrderNotPosition() {
        let first = RecordFixtures.set(kilograms: 60, reps: 5, at: RecordFixtures.day(1), position: 1)
        let second = RecordFixtures.set(kilograms: 50, reps: 5, at: RecordFixtures.day(2), position: 0)
        let third = RecordFixtures.set(kilograms: 70, reps: 5, at: RecordFixtures.day(3), position: 2)

        let ids = RecordBaseline.empty.recordSetIds(in: [second, first, third], profile: .weighted)

        #expect(ids == [third.id])
    }

    @Test func secondSetOfTheFirstWorkoutCanBeARecord() {
        let first = RecordFixtures.set(kilograms: 60, reps: 5, at: RecordFixtures.day(1), position: 0)
        let second = RecordFixtures.set(kilograms: 65, reps: 5, at: RecordFixtures.day(1).addingTimeInterval(60), position: 1)

        let ids = RecordBaseline.empty.recordSetIds(in: [first, second], profile: .weighted)

        #expect(ids == [second.id])
    }
}

struct ActiveWorkoutRecordTests {
    @Test func activeExerciseMarksSetsAgainstEarlierWorkouts() {
        let exercise = DomainFixtures.makeLibraryExercise()
        let baseline = RecordBaseline(sets: [RecordFixtures.set(kilograms: 60, reps: 8, at: RecordFixtures.day(0))])
        let equal = RecordFixtures.set(kilograms: 60, reps: 8, at: RecordFixtures.day(7), position: 0)
        let heavier = RecordFixtures.set(kilograms: 62.5, reps: 8, at: RecordFixtures.day(7).addingTimeInterval(120), position: 1)
        let planned = DomainFixtures.makeSet(position: 2, kilograms: 70, reps: 8, completedAt: nil)
        let workoutExercise = WorkoutExercise(
            id: UUID(),
            workoutId: UUID(),
            exerciseId: exercise.id,
            position: 0,
            targetSets: 3,
            targetReps: nil,
            restSeconds: Exercise.defaultRestSeconds
        )

        let active = ActiveWorkoutExercise(
            workoutExercise: workoutExercise,
            exercise: exercise,
            sets: [equal, heavier, planned],
            previousSets: [],
            recordBaseline: baseline
        )

        #expect(active.recordSetIds == [heavier.id])
    }
}
