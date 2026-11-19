import Foundation

public protocol WorkoutRepository: Sendable {
    func observeActive() -> AsyncThrowingStream<ActiveWorkout?, any Error>
    func activeWorkout() async throws -> ActiveWorkout?
    func start(_ workout: Workout, exercises: [WorkoutExercise], sets: [SetEntry]) async throws
    func addExercise(_ workoutExercise: WorkoutExercise, sets: [SetEntry]) async throws
    func addSet(_ entry: SetEntry) async throws
    func updateSet(_ entry: SetEntry) async throws
    func updateSets(_ entries: [SetEntry]) async throws
    func removeSet(id: UUID) async throws
    func updateNote(workoutId: UUID, note: String?) async throws
    func updateRest(workoutId: UUID, rest: RestPeriod?) async throws
    func finish(workoutId: UUID, at date: Date) async throws
    func cancel(workoutId: UUID) async throws
    func previousSets(exerciseId: UUID) async throws -> [SetEntry]
    func observeExerciseHistory(exerciseId: UUID) -> AsyncThrowingStream<ExerciseHistory?, any Error>
}
