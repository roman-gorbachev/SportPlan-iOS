import Domain
import Foundation
import Testing

struct HistoryUseCaseTests {
    private let exercise = DomainFixtures.makeLibraryExercise()

    @Test func historyHasFinishedWorkoutsOnly() async throws {
        let repository = FakeWorkoutRepository(library: [exercise])
        let finished = HistoryFixtures.workout(exercise: exercise, startedAt: RecordFixtures.day(-1), sets: HistoryFixtures.working(3))
        try await HistoryFixtures.log(finished, in: repository)
        let active = Workout(id: UUID(), programDay: nil, startedAt: RecordFixtures.day(0), finishedAt: nil, note: nil, rest: nil)
        try await repository.start(active, exercises: [], sets: [])
        let useCase = ObserveHistoryUseCase(repository: repository, now: { return RecordFixtures.day(0) }, calendar: HistoryFixtures.calendar)

        var overviews: [HistoryOverview] = []
        for try await overview in useCase.execute() {
            overviews.append(overview)
        }

        #expect(overviews.first?.entries.map(\.id) == [finished.id])
        #expect(overviews.first?.heatmap.workoutCount == 1)
    }

    @Test func finishedWorkoutStreamCarriesRecordsAndNilWhenMissing() async throws {
        let repository = FakeWorkoutRepository(library: [exercise])
        let first = HistoryFixtures.workout(exercise: exercise, startedAt: RecordFixtures.day(0), sets: HistoryFixtures.working(1, kilograms: 60, reps: 5))
        let better = HistoryFixtures.workout(exercise: exercise, startedAt: RecordFixtures.day(2), sets: HistoryFixtures.working(1, kilograms: 70, reps: 5))
        try await HistoryFixtures.log(first, in: repository)
        try await HistoryFixtures.log(better, in: repository)
        let useCase = ObserveFinishedWorkoutUseCase(repository: repository)

        var details: [FinishedWorkoutDetail?] = []
        for try await detail in useCase.execute(workoutId: better.id) {
            details.append(detail)
        }
        var missing: [FinishedWorkoutDetail?] = []
        for try await detail in useCase.execute(workoutId: UUID()) {
            missing.append(detail)
        }

        #expect(details.first??.recordCount == 1)
        #expect(missing.count == 1)
        #expect(missing.first == .some(nil))
    }

    @Test func deleteRemovesTheFinishedWorkoutButNotTheActiveOne() async throws {
        let repository = FakeWorkoutRepository(library: [exercise])
        let finished = HistoryFixtures.workout(exercise: exercise, startedAt: RecordFixtures.day(-1), sets: HistoryFixtures.working(2))
        try await HistoryFixtures.log(finished, in: repository)
        let active = Workout(id: UUID(), programDay: nil, startedAt: RecordFixtures.day(0), finishedAt: nil, note: nil, rest: nil)
        try await repository.start(active, exercises: [], sets: [])
        let useCase = DeleteWorkoutUseCase(repository: repository)

        try await useCase.execute(workoutId: finished.id)
        try await useCase.execute(workoutId: active.id)

        #expect(repository.workouts.map(\.id) == [active.id])
        #expect(repository.sets.isEmpty)
    }
}
