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
    func removeExercise(workoutExerciseId: UUID) async throws
    func updateNote(workoutId: UUID, note: String?) async throws
    func updateRest(workoutId: UUID, rest: RestPeriod?) async throws
    func finish(workoutId: UUID, at date: Date) async throws
    func cancel(workoutId: UUID) async throws
    func previousSets(exerciseId: UUID) async throws -> [SetEntry]
    func previousWorkoutExercise(exerciseId: UUID) async throws -> WorkoutExercise?
    func lastWorkoutDate(programDayId: UUID) async throws -> Date?
    func observeExerciseHistory(exerciseId: UUID) -> AsyncThrowingStream<ExerciseHistory?, any Error>
    func observeFinished() -> AsyncThrowingStream<[FinishedWorkout], any Error>
    func deleteFinished(workoutId: UUID) async throws
}
