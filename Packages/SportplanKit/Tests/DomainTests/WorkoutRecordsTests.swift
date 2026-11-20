import Domain
import Foundation
import Testing

struct WorkoutRecordsTests {
    private let exercise = DomainFixtures.makeLibraryExercise()

    @Test func onlySetsBeatingEarlierHistoryAreRecords() {
        let first = HistoryFixtures.workout(exercise: exercise, startedAt: RecordFixtures.day(0), sets: HistoryFixtures.working(3, kilograms: 60, reps: 5))
        let same = HistoryFixtures.workout(exercise: exercise, startedAt: RecordFixtures.day(3), sets: HistoryFixtures.working(3, kilograms: 60, reps: 5))
        let heavier = HistoryFixtures.workout(exercise: exercise, startedAt: RecordFixtures.day(7), sets: HistoryFixtures.working(1, kilograms: 62.5, reps: 5))

        let recordIds = WorkoutRecords.recordSetIds(in: [heavier, first, same])

        #expect(first.recordCount(in: recordIds) == 0)
        #expect(same.recordCount(in: recordIds) == 0)
        #expect(heavier.recordCount(in: recordIds) == 1)
    }

    @Test func warmupsNeverCountAsRecords() {
        let first = HistoryFixtures.workout(exercise: exercise, startedAt: RecordFixtures.day(0), sets: HistoryFixtures.working(1, kilograms: 60, reps: 5))
        let warmup = HistoryFixtures.workout(
            exercise: exercise,
            startedAt: RecordFixtures.day(3),
            sets: [(kilograms: 100, reps: 5, isWarmup: true)]
        )

        #expect(warmup.recordCount(in: WorkoutRecords.recordSetIds(in: [first, warmup])) == 0)
    }

    @Test func overviewListsNewestFirstWithRecordCounts() {
        let first = HistoryFixtures.workout(exercise: exercise, startedAt: RecordFixtures.day(0), sets: HistoryFixtures.working(2, kilograms: 60, reps: 5))
        let better = HistoryFixtures.workout(exercise: exercise, startedAt: RecordFixtures.day(2), sets: HistoryFixtures.working(2, kilograms: 65, reps: 5))

        let overview = HistoryOverview(workouts: [first, better], today: RecordFixtures.day(2), calendar: HistoryFixtures.calendar)

        #expect(overview.entries.map(\.id) == [better.id, first.id])
        #expect(overview.entries.map(\.recordCount) == [1, 0])
        #expect(better.workingSetCount == 2)
        #expect(better.durationSeconds == Int(HistoryFixtures.secondsPerHour))
    }
}
