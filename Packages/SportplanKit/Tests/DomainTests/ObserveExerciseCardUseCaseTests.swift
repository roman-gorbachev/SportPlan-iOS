import Domain
import Foundation
import Testing

struct ObserveExerciseCardUseCaseTests {
    @Test func missingExerciseFailsWithNotFound() async {
        let useCase = ObserveExerciseCardUseCase(repository: FakeWorkoutRepository())

        await #expect(throws: ExerciseError.notFound) {
            for try await _ in useCase.execute(exerciseId: UUID()) {}
        }
    }

    @Test func exerciseWithoutHistoryHasNoData() async throws {
        let exercise = DomainFixtures.makeLibraryExercise()
        let useCase = ObserveExerciseCardUseCase(repository: FakeWorkoutRepository(library: [exercise]))

        var cards: [ExerciseCard] = []
        for try await card in useCase.execute(exerciseId: exercise.id) {
            cards.append(card)
        }

        #expect(cards.count == 1)
        #expect(cards.first?.hasData == false)
        #expect(cards.first?.series.map(\.metric) == [.estimatedOneRepMax, .maxWeight])
    }

    @Test func cardMarksRecordSessionsNewestFirst() {
        let exercise = DomainFixtures.makeLibraryExercise()
        let first = RecordFixtures.session(day: 0, [RecordFixtures.set(kilograms: 60, reps: 5, at: RecordFixtures.day(0))])
        let flat = RecordFixtures.session(day: 3, [RecordFixtures.set(kilograms: 60, reps: 5, at: RecordFixtures.day(3))])
        let better = RecordFixtures.session(day: 7, [RecordFixtures.set(kilograms: 62.5, reps: 5, at: RecordFixtures.day(7))])

        let card = ExerciseCard(history: ExerciseHistory(exercise: exercise, sessions: [first, better, flat]))

        #expect(card.sessions.map(\.workoutId) == [better.workoutId, flat.workoutId, first.workoutId])
        #expect(card.sessions.map(card.hasRecord(in:)) == [true, false, false])
    }
}
