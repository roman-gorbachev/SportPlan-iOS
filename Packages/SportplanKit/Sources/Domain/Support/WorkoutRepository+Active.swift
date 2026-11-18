import Foundation

extension WorkoutRepository {
    func requiredActiveWorkout() async throws -> ActiveWorkout {
        guard let active = try await activeWorkout() else {
            throw WorkoutError.noActiveWorkout
        }
        return active
    }

    func requiredSet(id: UUID) async throws -> (item: ActiveWorkoutExercise, entry: SetEntry) {
        let active = try await requiredActiveWorkout()
        guard let item = active.exercise(containingSetId: id), let entry = item.set(id: id) else {
            throw WorkoutError.notFound
        }
        return (item: item, entry: entry)
    }
}
