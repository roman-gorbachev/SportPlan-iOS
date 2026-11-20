import Domain
import Foundation
import Testing

struct ExerciseArchiveUseCaseTests {
    private static let workoutCount = 6

    @Test func archivedExercisesAreSortedByName() async throws {
        let squat = ArchivedExercise(exercise: DomainFixtures.makeLibraryExercise(name: "Тяга Т-грифа"), workoutCount: 0)
        let press = ArchivedExercise(exercise: DomainFixtures.makeLibraryExercise(name: "Жим Арнольда", kind: .dumbbell), workoutCount: Self.workoutCount)
        let repository = FakeExerciseRepository(archived: [squat, press])
        var iterator = ObserveArchivedExercisesUseCase(repository: repository).execute().makeAsyncIterator()
        let archived = try await iterator.next()
        #expect(archived == [press, squat])
    }

    @Test func restoreGoesToTheRepository() async throws {
        let repository = FakeExerciseRepository()
        let id = UUID()
        try await RestoreExerciseUseCase(repository: repository).execute(id: id)
        #expect(repository.restoredIds == [id])
    }
}
