import Foundation

public struct RemoveExerciseFromWorkoutUseCase: Sendable {
    private let repository: any WorkoutRepository
    private let scheduler: any RestNotificationScheduler

    public init(repository: any WorkoutRepository, scheduler: any RestNotificationScheduler) {
        self.repository = repository
        self.scheduler = scheduler
    }

    public func execute(workoutExerciseId: UUID) async throws {
        let active = try await repository.requiredActiveWorkout()
        guard let item = active.exercise(id: workoutExerciseId) else {
            throw WorkoutError.notFound
        }
        let restInvolvesExercise = active.workout.rest != nil && Self.restInvolves(item, in: active)
        let hasRunningSet = active.runningSet?.exercise.id == item.id
        try await repository.removeExercise(workoutExerciseId: workoutExerciseId)
        if hasRunningSet {
            await scheduler.cancelSetEnd()
        }
        if restInvolvesExercise {
            try await repository.updateRest(workoutId: active.id, rest: nil)
            await scheduler.cancel()
        }
    }

    private static func restInvolves(_ item: ActiveWorkoutExercise, in active: ActiveWorkout) -> Bool {
        guard let trigger = active.restTrigger else {
            return false
        }
        return trigger.exercise.id == item.id || active.nextPlannedSet(after: trigger)?.exercise.id == item.id
    }
}
