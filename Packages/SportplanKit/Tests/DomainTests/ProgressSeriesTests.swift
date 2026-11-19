import Domain
import Testing

struct ProgressSeriesTests {
    private let exercise = DomainFixtures.makeLibraryExercise()

    @Test func takesTheBestValueOfEachWorkout() {
        let history = ExerciseHistory(exercise: exercise, sessions: [
            RecordFixtures.session(day: 0, [
                RecordFixtures.set(kilograms: 60, reps: 5, at: RecordFixtures.day(0)),
                RecordFixtures.set(kilograms: 62.5, reps: 3, at: RecordFixtures.day(0)),
            ]),
            RecordFixtures.session(day: 7, [RecordFixtures.set(kilograms: 65, reps: 5, at: RecordFixtures.day(7))]),
        ])

        let series = ProgressSeries(history: history, metric: .maxWeight)

        #expect(series.points.map(\.value) == [62_500, 65_000])
        #expect(series.points.map(\.isRecord) == [false, true])
        #expect(series.latest == 65_000)
        #expect(series.delta == 2_500)
    }

    @Test func windowEndsAtTheLastWorkout() {
        let history = ExerciseHistory(exercise: exercise, sessions: [
            RecordFixtures.session(day: 0, [RecordFixtures.set(kilograms: 50, reps: 5, at: RecordFixtures.day(0))]),
            RecordFixtures.session(day: 100, [RecordFixtures.set(kilograms: 55, reps: 5, at: RecordFixtures.day(100))]),
            RecordFixtures.session(day: 150, [RecordFixtures.set(kilograms: 60, reps: 5, at: RecordFixtures.day(150))]),
        ])

        let series = ProgressSeries(history: history, metric: .maxWeight)

        #expect(series.points.map(\.value) == [55_000, 60_000])
        #expect(series.points.map(\.isRecord) == [true, true])
    }

    @Test func singlePointHasNoDelta() {
        let history = ExerciseHistory(exercise: exercise, sessions: [
            RecordFixtures.session(day: 0, [RecordFixtures.set(kilograms: 50, reps: 5, at: RecordFixtures.day(0))]),
        ])

        let series = ProgressSeries(history: history, metric: .maxWeight)

        #expect(series.latest == 50_000)
        #expect(series.delta == nil)
        #expect(series.points.first?.isRecord == false)
    }

    @Test func workoutWithoutRepsUpToTwelveHasNoOneRepMaxPoint() {
        let history = ExerciseHistory(exercise: exercise, sessions: [
            RecordFixtures.session(day: 0, [RecordFixtures.set(kilograms: 40, reps: 15, at: RecordFixtures.day(0))]),
            RecordFixtures.session(day: 7, [RecordFixtures.set(kilograms: 60, reps: 1, at: RecordFixtures.day(7))]),
        ])

        let series = ProgressSeries(history: history, metric: .estimatedOneRepMax)

        #expect(series.points.map(\.value) == [60_000])
    }
}
